import { cn } from '@/lib/utils'

interface AvatarCircleProps {
  initials: string
  size?: 'sm' | 'md' | 'lg'
  className?: string
}

const sizeClasses = {
  sm: 'w-8 h-8 text-xs',
  md: 'w-10 h-10 text-sm',
  lg: 'w-12 h-12 text-base',
}

export function AvatarCircle({ initials, size = 'md', className }: AvatarCircleProps) {
  return (
    <div
      className={cn(
        'rounded-full bg-[#1DB8A4] flex items-center justify-center text-white font-medium shrink-0',
        sizeClasses[size],
        className
      )}
    >
      {initials}
    </div>
  )
}
