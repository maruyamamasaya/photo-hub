import type { Asset, AssetFile } from './generated/contracts';

export class ApiFailure extends Error {
  constructor(public code: string, message: string) { super(message); }
}
export async function api<T>(path: string, method = 'GET', body?: unknown, signal?: AbortSignal): Promise<T> {
  const response = await fetch(`/api/v1${path}`, { method, signal, headers: body instanceof FormData ? undefined : { 'Content-Type': 'application/json' }, body: body === undefined ? undefined : body instanceof FormData ? body : JSON.stringify(body) });
  if (!response.ok) {
    const error = await response.json().catch(() => ({ code: 'network', message: '通信に失敗しました。' }));
    throw new ApiFailure(error.code, error.message);
  }
  return response.json();
}
export function fileUrl(asset: Asset, file: AssetFile, download = false) {
  return `/api/v1/assets/${asset.id}/files/${file.id}/content${download ? '?download=true' : ''}`;
}
export function bytes(value: number) {
  if (value < 1024) return `${value} B`;
  if (value < 1024 * 1024) return `${(value / 1024).toFixed(0)} KB`;
  return `${(value / 1024 / 1024).toFixed(1)} MB`;
}
