export type CartLine = { productId: string; name: string; price: number; quantity: number; stock: number };
export const formatBDT = (amount: number) => `৳${new Intl.NumberFormat('en-BD', { minimumFractionDigits: 2, maximumFractionDigits: 2 }).format(amount)}`;
export function cartTotal(lines: CartLine[]): number { return lines.reduce((sum, line) => sum + line.price * line.quantity, 0); }
export function validateSale(lines: CartLine[]): string | null {
  if (!lines.length) return 'Add at least one product to the sale.';
  for (const line of lines) {
    if (!Number.isInteger(line.quantity) || line.quantity <= 0) return `Enter a whole quantity greater than zero for ${line.name}.`;
    if (line.quantity > line.stock) return `Not enough stock for ${line.name}. Only ${line.stock} available.`;
    if (!Number.isFinite(line.price) || line.price < 0) return `Invalid price for ${line.name}.`;
  }
  return null;
}
export const dhakaDate = (date: string | Date) => new Intl.DateTimeFormat('en-BD', { timeZone: 'Asia/Dhaka', dateStyle: 'medium' }).format(new Date(date));
export const dhakaDateTime = (date: string | Date) => new Intl.DateTimeFormat('en-BD', { timeZone: 'Asia/Dhaka', dateStyle: 'medium', timeStyle: 'short' }).format(new Date(date));
export const dhakaDateKey = (date: string | Date) => new Intl.DateTimeFormat('en-CA', { timeZone: 'Asia/Dhaka', year: 'numeric', month: '2-digit', day: '2-digit' }).format(new Date(date));
