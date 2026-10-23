create extension if not exists pgcrypto;

create table public.shops (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null unique references auth.users(id) on delete cascade,
  name text not null check (char_length(trim(name)) between 1 and 100),
  created_at timestamptz not null default now()
);

create table public.products (
  id uuid primary key default gen_random_uuid(),
  shop_id uuid not null references public.shops(id) on delete cascade,
  name text not null check (char_length(trim(name)) between 1 and 150),
  sku text check (sku is null or char_length(sku) <= 80),
  category text check (category is null or char_length(category) <= 80),
  cost_price numeric(12,2) not null check (cost_price >= 0),
  selling_price numeric(12,2) not null check (selling_price >= 0),
  stock integer not null default 0 check (stock >= 0),
  low_stock_threshold integer not null default 5 check (low_stock_threshold >= 0),
  archived boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index products_shop_created_idx on public.products(shop_id, created_at desc);
create index products_shop_category_idx on public.products(shop_id, category);
create unique index products_shop_sku_unique on public.products(shop_id, lower(sku)) where sku is not null;

create table public.sales (
  id uuid primary key default gen_random_uuid(),
  shop_id uuid not null references public.shops(id) on delete cascade,
  total numeric(14,2) not null check (total >= 0),
  created_at timestamptz not null default now()
);
create index sales_shop_created_idx on public.sales(shop_id, created_at desc);

create table public.sale_items (
  id uuid primary key default gen_random_uuid(),
  sale_id uuid not null references public.sales(id) on delete cascade,
  product_id uuid references public.products(id) on delete set null,
  product_name text not null,
  unit_price numeric(12,2) not null check (unit_price >= 0),
  quantity integer not null check (quantity > 0),
  line_total numeric(14,2) generated always as (unit_price * quantity) stored
);
create index sale_items_sale_idx on public.sale_items(sale_id);

alter table public.shops enable row level security;
alter table public.products enable row level security;
alter table public.sales enable row level security;
alter table public.sale_items enable row level security;

create policy "Owners manage their shop" on public.shops for all to authenticated using (owner_id = (select auth.uid())) with check (owner_id = (select auth.uid()));
create policy "Owners manage their products" on public.products for all to authenticated using (exists (select 1 from public.shops s where s.id = shop_id and s.owner_id = (select auth.uid()))) with check (exists (select 1 from public.shops s where s.id = shop_id and s.owner_id = (select auth.uid())));
create policy "Owners read their sales" on public.sales for select to authenticated using (exists (select 1 from public.shops s where s.id = shop_id and s.owner_id = (select auth.uid())));
create policy "Owners read their sale items" on public.sale_items for select to authenticated using (exists (select 1 from public.sales sa join public.shops s on s.id = sa.shop_id where sa.id = sale_id and s.owner_id = (select auth.uid())));

grant select, insert, update, delete on public.shops, public.products to authenticated;
grant select on public.sales, public.sale_items to authenticated;
revoke all on public.shops, public.products, public.sales, public.sale_items from anon;

create or replace function public.record_sale(p_shop_id uuid, p_items jsonb)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_sale_id uuid;
  v_item jsonb;
  v_product public.products%rowtype;
  v_quantity integer;
  v_total numeric(14,2) := 0;
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  if not exists (select 1 from public.shops where id = p_shop_id and owner_id = auth.uid()) then
    raise exception 'Shop not found or access denied';
  end if;
  if jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) = 0 then
    raise exception 'A sale must include at least one item';
  end if;
  if (select count(*) from jsonb_array_elements(p_items)) <>
     (select count(distinct value->>'product_id') from jsonb_array_elements(p_items)) then
    raise exception 'A product can appear only once in a sale';
  end if;
  -- Lock product rows in stable UUID order, then validate the complete sale before changing stock.
  for v_item in select value from jsonb_array_elements(p_items) order by value->>'product_id' loop
    if coalesce(v_item->>'quantity','') !~ '^[0-9]+$' then raise exception 'Quantity must be a positive whole number'; end if;
    v_quantity := (v_item->>'quantity')::integer;
    if v_quantity <= 0 then raise exception 'Quantity must be a positive whole number'; end if;
    select * into v_product from public.products where id = (v_item->>'product_id')::uuid and shop_id = p_shop_id and not archived for update;
    if not found then raise exception 'Product not found or unavailable'; end if;
    if v_product.stock < v_quantity then raise exception 'Insufficient stock for % (available: %)', v_product.name, v_product.stock; end if;
    v_total := v_total + v_product.selling_price * v_quantity;
  end loop;
  insert into public.sales(shop_id,total) values (p_shop_id,v_total) returning id into v_sale_id;
  for v_item in select value from jsonb_array_elements(p_items) order by value->>'product_id' loop
    v_quantity := (v_item->>'quantity')::integer;
    select * into v_product from public.products where id = (v_item->>'product_id')::uuid and shop_id = p_shop_id for update;
    update public.products set stock = stock - v_quantity, updated_at = now() where id = v_product.id;
    insert into public.sale_items(sale_id, product_id, product_name, unit_price, quantity)
    values (v_sale_id, v_product.id, v_product.name, v_product.selling_price, v_quantity);
  end loop;
  return v_sale_id;
end;
$$;
revoke all on function public.record_sale(uuid,jsonb) from public, anon;
grant execute on function public.record_sale(uuid,jsonb) to authenticated;
