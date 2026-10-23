import { describe, expect, it } from 'vitest';
import { cartTotal, formatBDT, validateSale, type CartLine } from './lib';
const line=(overrides:Partial<CartLine>={}):CartLine=>({productId:'p1',name:'Rice',price:165,quantity:2,stock:10,...overrides});
describe('sale calculations and validation',()=>{
 it('calculates a cart subtotal',()=>expect(cartTotal([line(),line({productId:'p2',price:95,quantity:1})])).toBe(425));
 it('rejects insufficient stock',()=>expect(validateSale([line({quantity:11})])).toMatch(/Not enough stock/));
 it('rejects zero, negative, and fractional quantities',()=>{expect(validateSale([line({quantity:0})])).toMatch(/whole quantity/);expect(validateSale([line({quantity:-1})])).toMatch(/whole quantity/);expect(validateSale([line({quantity:1.5})])).toMatch(/whole quantity/)});
 it('rejects an empty sale',()=>expect(validateSale([])).toMatch(/at least one product/));
 it('formats amounts as BDT',()=>expect(formatBDT(1234)).toContain('৳')); 
});
