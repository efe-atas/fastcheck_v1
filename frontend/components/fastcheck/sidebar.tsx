'use client'

import Link from 'next/link'
import { usePathname, useRouter } from 'next/navigation'
import { Home, FileText, Camera, BarChart2, Users, CheckSquare, LogOut } from 'lucide-react'
import { cn } from '@/lib/utils'
import { AvatarCircle } from './avatar-circle'

const navItems = [
  { label: 'Ana Sayfa', href: '/teacher/dashboard', icon: Home },
  { label: 'Sınavlar', href: '/teacher/exams', icon: FileText },
  { label: 'OCR Lab', href: '/teacher/ocr', icon: Camera },
  { label: 'Raporlar', href: '/teacher/reports', icon: BarChart2 },
  { label: 'Sınıflarım', href: '/teacher/classes', icon: Users },
]

export function Sidebar() {
  const pathname = usePathname()
  const router = useRouter()

  const handleLogout = () => {
    if (typeof window !== 'undefined') {
      localStorage.removeItem('access_token')
      localStorage.removeItem('refresh_token')
      router.push('/login')
    }
  }

  return (
    <aside className="w-[280px] h-screen fixed left-0 top-0 bg-[#2D5BFF] flex flex-col z-50">
      {/* Logo */}
      <div className="flex items-center gap-3 px-6 py-5 border-b border-white/10">
        <div className="w-8 h-8 bg-white/20 rounded-xl flex items-center justify-center">
          <CheckSquare size={18} className="text-white" />
        </div>
        <span className="text-white font-bold text-lg">FastCheck</span>
      </div>

      {/* Navigation */}
      <nav className="flex-1 px-3 py-4 space-y-1">
        {navItems.map((item) => {
          const isActive = pathname.startsWith(item.href)
          return (
            <Link
              key={item.href}
              href={item.href}
              className={cn(
                'flex items-center gap-3 px-6 py-3 text-[15px] font-medium transition-colors relative',
                isActive
                  ? 'text-white bg-white/15 rounded-r-full mr-4 before:absolute before:left-0 before:top-2.5 before:bottom-2.5 before:w-1 before:bg-white before:rounded-r-full'
                  : 'text-white/60 hover:text-white/90 hover:bg-white/10 rounded-xl mx-3 px-3'
              )}
            >
              <item.icon size={18} />
              {item.label}
            </Link>
          )
        })}

        <div className="pt-2 mt-2 border-t border-white/10 mx-3">
          <button
            onClick={handleLogout}
            className="w-full flex items-center gap-3 px-3 py-3 text-[15px] font-medium text-white/60 hover:text-[#EF4444] hover:bg-white/10 rounded-xl transition-colors text-left"
          >
            <LogOut size={18} />
            Çıkış Yap
          </button>
        </div>
      </nav>

      {/* User Profile */}
      <div className="px-4 py-4 border-t border-white/10">
        <div className="flex items-center gap-3">
          <AvatarCircle initials="AY" size="md" />
          <div className="flex-1 min-w-0">
            <p className="text-white text-sm font-medium truncate">Ayşe Yılmaz</p>
            <span className="text-[10px] font-medium text-white border border-white/40 rounded-full px-2 py-0.5 inline-block mt-0.5">
              ÖĞRETMEN
            </span>
          </div>
        </div>
      </div>
    </aside>
  )
}
