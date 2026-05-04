import { cn } from '@/lib/utils'
import type { ExamStatus } from '@/lib/mock-data'

const statusConfig: Record<ExamStatus, { bg: string; text: string }> = {
  'Hazır': { bg: 'bg-[#E1F5F2]', text: 'text-[#0D7A6A]' },
  'Taslak': { bg: 'bg-[#F3F4F6]', text: 'text-[#6B7280]' },
  'İşleniyor': { bg: 'bg-[#FFFBEB]', text: 'text-[#B45309]' },
  'Tamamlandı': { bg: 'bg-[#E1F5F2]', text: 'text-[#0D7A6A]' },
  'Başarısız': { bg: 'bg-[#FEF2F2]', text: 'text-[#B91C1C]' },
  'Atama Bekliyor': { bg: 'bg-[#FFFBEB]', text: 'text-[#B45309]' },
}

interface StatusBadgeProps {
  status: ExamStatus
  className?: string
}

export function StatusBadge({ status, className }: StatusBadgeProps) {
  const config = statusConfig[status] ?? { bg: 'bg-[#F3F4F6]', text: 'text-[#6B7280]' }
  return (
    <span
      className={cn(
        'inline-flex items-center rounded-full px-3 py-1 text-xs font-medium tracking-wide',
        config.bg,
        config.text,
        className
      )}
    >
      {status}
    </span>
  )
}
