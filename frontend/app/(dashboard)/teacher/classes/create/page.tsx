'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import Link from 'next/link'
import { Building2, ChevronLeft, Loader2, Save } from 'lucide-react'
import { api } from '@/lib/api-client'
import { mutate } from 'swr'

export default function CreateClassPage() {
  const router = useRouter()
  const [className, setClassName] = useState('')
  const [isLoading, setIsLoading] = useState(false)
  const [error, setError] = useState('')

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!className.trim()) {
      setError('Lütfen sınıf adını girin.')
      return
    }

    setIsLoading(true)
    setError('')

    try {
      await api.createClass({ className: className.trim() })
      // Cache'i temizle/yenile
      mutate('teacherClasses')
      router.push('/teacher/classes')
    } catch (err: any) {
      setError(err.message || 'Sınıf oluşturulurken bir hata oluştu.')
    } finally {
      setIsLoading(false)
    }
  }

  return (
    <div className="space-y-6 max-w-2xl mx-auto">
      {/* Header */}
      <div className="flex items-center gap-3">
        <Link href="/teacher/classes" className="w-10 h-10 bg-white border border-[#DDE3F0] rounded-xl flex items-center justify-center text-[#6B7A99] hover:text-[#0F1729] hover:bg-[#F8FAFC] transition-colors">
          <ChevronLeft size={20} />
        </Link>
        <div>
          <h1 className="text-2xl font-bold text-[#0F1729]">Yeni Sınıf Ekle</h1>
          <p className="text-sm text-[#8A96B2]">Sınavlarınızı düzenlemek için bir sınıf oluşturun.</p>
        </div>
      </div>

      {/* Form Card */}
      <div className="bg-white rounded-2xl border border-[#DDE3F0] shadow-sm p-6">
        <form onSubmit={handleSubmit} className="space-y-6">
          <div>
            <label htmlFor="className" className="block text-[15px] font-bold text-[#0F1729] mb-2">
              Sınıf Adı
            </label>
            <div className="relative">
              <Building2 size={18} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-[#9CA3AF]" />
              <input
                id="className"
                type="text"
                value={className}
                onChange={(e) => {
                  setClassName(e.target.value)
                  setError('')
                }}
                placeholder="Örn: 10-A, 11-B Fizik"
                disabled={isLoading}
                className="w-full bg-white border border-[#DDE3F0] rounded-xl pl-10 pr-4 py-3 text-[15px] text-[#0F1729] placeholder:text-[#9CA3AF] focus:outline-none focus:border-[#3B4FD8] focus:ring-1 focus:ring-[#3B4FD8] transition-all disabled:opacity-50 disabled:bg-[#F8FAFC]"
                autoFocus
              />
            </div>
            {error && <p className="text-sm text-[#EF4444] mt-2 font-medium">{error}</p>}
          </div>

          <div className="pt-2">
            <button
              type="submit"
              disabled={isLoading || !className.trim()}
              className="w-full bg-[#3B4FD8] text-white px-4 py-3.5 rounded-xl text-[16px] font-bold hover:bg-[#2D3DB8] transition-colors flex items-center justify-center gap-2 shadow-sm disabled:opacity-50 disabled:hover:bg-[#3B4FD8]"
            >
              {isLoading ? (
                <>
                  <Loader2 size={20} className="animate-spin" />
                  Oluşturuluyor...
                </>
              ) : (
                <>
                  <Save size={20} />
                  Sınıfı Oluştur
                </>
              )}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}
