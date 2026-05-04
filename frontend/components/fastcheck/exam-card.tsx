'use client'

import Link from 'next/link'
import { Calendar, ClipboardCheck } from 'lucide-react'
import { StatusBadge } from './status-badge'
import type { ExamStatus } from '@/lib/mock-data'
import { cn } from '@/lib/utils'

interface ExamCardProps {
  id: string
  name: string
  className: string
  dateShort: string
  status: ExamStatus
  href?: string
  showOcrButton?: boolean
  onOcrClick?: () => void
  compact?: boolean
}

export function ExamCard({
  id,
  name,
  className,
  dateShort,
  status,
  href,
  showOcrButton = false,
  onOcrClick,
  compact = false,
}: ExamCardProps) {
  const content = (
    <div className={cn('bg-white rounded-2xl shadow-sm border-l-4 border-l-[#2D5BFF] p-4 w-full hover:shadow-md transition-shadow', compact ? 'py-3' : '')}>
      <div className="flex items-start justify-between gap-3">
        <div className="flex-1 min-w-0">
          <div className="flex items-center gap-2 mb-1">
            <span className="inline-flex items-center rounded-full bg-[#F3F4F6] px-2 py-0.5 text-[11px] font-medium text-[#6B7280] uppercase tracking-wide">
              {className}
            </span>
          </div>
          <h3 className="text-base font-semibold text-[#111827] truncate">{name}</h3>
          <div className="flex items-center gap-1 mt-1">
            <Calendar size={11} className="text-[#9CA3AF]" />
            <span className="text-[13px] text-[#9CA3AF]">{dateShort}</span>
            <StatusBadge status={status} className="ml-2" />
          </div>
        </div>
        <div className="flex flex-col items-end gap-2 shrink-0">
          {showOcrButton && (
            <button
              onClick={(e) => { e.preventDefault(); onOcrClick?.() }}
              className="w-9 h-9 rounded-xl bg-[#E8EDFF] flex items-center justify-center text-[#2D5BFF] hover:bg-[#2D5BFF] hover:text-white transition-colors"
              title="OCR Lab"
            >
              <ClipboardCheck size={16} />
            </button>
          )}
          <span className="text-[13px] font-medium text-[#2D5BFF]">Detaylar &rsaquo;</span>
        </div>
      </div>
    </div>
  )

  if (href) {
    return <Link href={href} className="block">{content}</Link>
  }

  return content
}
