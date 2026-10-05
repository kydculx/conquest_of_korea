import React from 'react';
import { ChevronLeft, ChevronRight } from 'lucide-react';

function pageWindow(page, totalPages) {
  const start = Math.max(1, Math.min(page - 2, totalPages - 4));
  const end = Math.min(totalPages, start + 4);
  const nums = [];
  for (let n = Math.max(1, end - 4); n <= end; n += 1) nums.push(n);
  return nums;
}

export default function Pagination({ page, totalPages, totalCount, pageSize, onChange }) {
  if (!totalPages || totalPages <= 1) return null;
  return (
    <div className="pagination">
      <button
        type="button"
        className="page-btn"
        disabled={page <= 1}
        onClick={() => onChange(page - 1)}
        aria-label="이전 페이지"
      >
        <ChevronLeft size={15} />
      </button>
      {pageWindow(page, totalPages).map((n) => (
        <button
          key={n}
          type="button"
          className={`page-btn ${n === page ? 'active' : ''}`}
          onClick={() => onChange(n)}
        >
          {n}
        </button>
      ))}
      <button
        type="button"
        className="page-btn"
        disabled={page >= totalPages}
        onClick={() => onChange(page + 1)}
        aria-label="다음 페이지"
      >
        <ChevronRight size={15} />
      </button>
      <span className="pagination-info">
        {page} / {totalPages} 페이지 · 총 {totalCount.toLocaleString()}건 ({pageSize}건씩)
      </span>
    </div>
  );
}
