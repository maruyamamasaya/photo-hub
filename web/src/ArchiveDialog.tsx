import { useEffect, useState } from 'react';
import type { ArchiveResult, AssetSelection, BulkArchiveRequest, Collection, CollectionArchiveRequest, CollectionArchiveSummary } from './generated/contracts';
import { api } from './api';
import { Modal } from './Modal';

export type ArchiveAction = { archived: boolean; target: { assets: AssetSelection[] } | { collection: Collection } };

export function ArchiveDialog({ action, onClose, onChanged, onReload }: { action: ArchiveAction; onClose: () => void; onChanged: (message: string) => void; onReload: () => void }) {
  const collection = 'collection' in action.target ? action.target.collection : null;
  const collectionId = collection?.id;
  const [summary, setSummary] = useState<CollectionArchiveSummary | null>(null);
  const [attempt, setAttempt] = useState(0);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');
  const [stale, setStale] = useState(false);
  const label = action.archived ? 'アーカイブする' : '通常に戻す';
  const count = 'assets' in action.target ? action.target.assets.length : summary ? action.archived ? summary.normalCount : summary.archiveCount : null;

  useEffect(() => {
    if (!collectionId) return;
    const abort = new AbortController();
    setSummary(null); setError(''); setStale(false);
    api<CollectionArchiveSummary>(`/collections/${collectionId}/archive-summary`, 'GET', undefined, abort.signal)
      .then(value => { if (!abort.signal.aborted) setSummary(value); })
      .catch(e => { if (!abort.signal.aborted) setError(e instanceof Error ? e.message : '対象件数を読み込めません。'); });
    return () => abort.abort();
  }, [collectionId, attempt]);

  async function submit() {
    if (busy || count === null || !count || stale) return;
    setBusy(true); setError('');
    try {
      const result = 'assets' in action.target
        ? await api<ArchiveResult>('/bulk-archive', 'POST', { assets: action.target.assets, archived: action.archived } satisfies BulkArchiveRequest)
        : await api<ArchiveResult>(`/collections/${action.target.collection.id}/archive`, 'POST', { archived: action.archived, token: summary!.token } satisfies CollectionArchiveRequest);
      onChanged(`${result.updated} 点を${action.archived ? 'アーカイブしました' : '通常に戻しました'}。`);
      onClose();
    } catch (e) {
      setError(e instanceof Error ? e.message : '変更に失敗しました。');
      // A fresh preview is required before resubmitting a collection operation.
      if (collectionId) setStale(true);
    } finally { setBusy(false); }
  }

  return <Modal title={label} onClose={() => { if (!busy) onClose(); }}>
    <div className="settings-body">
      {collection ? <p>「{collection.name}」内のリモート素材が対象です。検索やフィルター、表示中のページによる絞り込みは適用しません。</p> : null}
      <p>{count === null ? '対象件数を読み込んでいます…' : `${count} 点を${action.archived ? 'アーカイブします' : '通常に戻します'}。`}</p>
      <p>タグやコレクション所属は保持します。同じ素材は、他のコレクションでも同じ保管状態になります。ごみ箱の素材は対象外です。</p>
      <p className="muted">開発用リモートでは原本の配置・使用容量は変わりません。</p>
      {error ? <div className="error-box" role="alert">{error}</div> : null}
      {collectionId && (stale || error) ? <button className="secondary" disabled={busy} onClick={() => setAttempt(value => value + 1)}>対象件数を読み込み直す</button> : null}
      {!collectionId && error ? <button className="secondary" disabled={busy} onClick={() => { onClose(); onReload(); }}>最新の一覧を読み込む</button> : null}
      <div className="list-settings-actions"><button className="secondary" disabled={busy} onClick={onClose}>キャンセル</button><button className="primary" disabled={busy || !count || stale} onClick={submit}>{busy ? '変更中…' : label}</button></div>
    </div>
  </Modal>;
}
