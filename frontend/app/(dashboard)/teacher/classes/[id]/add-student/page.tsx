'use client'

import { use, useState } from 'react'
import { useRouter } from 'next/navigation'
import Link from 'next/link'
import { UserPlus, ChevronLeft, Loader2, Save, User, Mail } from 'lucide-react'
import { api } from '@/lib/api-client'
import { mutate } from 'swr'

export default function AddStudentPage({ params }: { params: Promise<{ id: string }> }) {
  const resolvedParams = use(params)
  const classId = parseInt(resolvedParams.id, 10)
  
  const router = useRouter()
  const [fullName, setFullName] = useState('')
  const [email, setEmail] = useState('')
  const [isLoading, setIsLoading] = useState(false)
  const [error, setError] = useState('')

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    
    if (!fullName.trim() || !email.trim()) {
      setError('Lütfen tüm alanları doldurun.')
      return
    }

    if (!email.includes('@')) {
      setError('Lütfen geçerli bir e-posta adresi girin.')
      return
    }

    setIsLoading(true)
    setError('')

    try {
      await api.addStudentToClass(classId, { 
        fullName: fullName.trim(), 
        email: email.trim() 
      })
      // Sınıf öğrencileri listesini yenile
      mutate(`classStudents-${classId}`)
      router.push(`/teacher/classes/${classId}`)
    } catch (err: any) {
      setError(err.message || 'Öğrenci eklenirken bir hata oluştu.')
    } finally {
      setIsLoading(false)
    }
  }

  return (
    <div className="space-y-6 max-w-2xl mx-auto">
      {/* Header */}
      <div className="flex items-center gap-3">
        <Link href={`/teacher/classes/${classId}`} className="w-10 h-10 bg-white border border-[#DDE3F0] rounded-xl flex items-center justify-center text-[#6B7A99] hover:text-[#0F1729] hover:bg-[#F8FAFC] transition-colors">
          <ChevronLeft size={20} />
        </Link>
        <div>
          <h1 className="text-2xl font-bold text-[#0F1729]">Öğrenci Ekle</h1>
          <p className="text-sm text-[#8A96B2]">Sınıf ID: {classId}</p>
        </div>
      </div>

      {/* Form Card */}
      <div className="bg-white rounded-2xl border border-[#DDE3F0] shadow-sm p-6">
        <form onSubmit={handleSubmit} className="space-y-5">
          <div>
            <label htmlFor="fullName" className="block text-[15px] font-bold text-[#0F1729] mb-2">
              Öğrenci Adı Soyadı
            </label>
            <div className="relative">
              <User size={18} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-[#9CA3AF]" />
              <input
                id="fullName"
                type="text"
                value={fullName}
                onChange={(e) => {
                  setFullName(e.target.value)
                  setError('')
                }}
                placeholder="Örn: Ahmet Yılmaz"
                disabled={isLoading}
                className="w-full bg-white border border-[#DDE3F0] rounded-xl pl-10 pr-4 py-3 text-[15px] text-[#0F1729] placeholder:text-[#9CA3AF] focus:outline-none focus:border-[#3B4FD8] focus:ring-1 focus:ring-[#3B4FD8] transition-all disabled:opacity-50 disabled:bg-[#F8FAFC]"
                autoFocus
              />
            </div>
          </div>

          <div>
            <label htmlFor="email" className="block text-[15px] font-bold text-[#0F1729] mb-2">
              E-Posta Adresi
            </label>
            <div className="relative">
              <Mail size={18} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-[#9CA3AF]" />
              <input
                id="email"
                type="email"
                value={email}
                onChange={(e) => {
                  setEmail(e.target.value)
                  setError('')
                }}
                placeholder="Örn: ahmet@ogrenci.com"
                disabled={isLoading}
                className="w-full bg-white border border-[#DDE3F0] rounded-xl pl-10 pr-4 py-3 text-[15px] text-[#0F1729] placeholder:text-[#9CA3AF] focus:outline-none focus:border-[#3B4FD8] focus:ring-1 focus:ring-[#3B4FD8] transition-all disabled:opacity-50 disabled:bg-[#F8FAFC]"
              />
            </div>
            {error && <p className="text-sm text-[#EF4444] mt-2 font-medium">{error}</p>}
          </div>

          <div className="pt-3">
            <button
              type="submit"
              disabled={isLoading || !fullName.trim() || !email.trim()}
              className="w-full bg-[#3B4FD8] text-white px-4 py-3.5 rounded-xl text-[16px] font-bold hover:bg-[#2D3DB8] transition-colors flex items-center justify-center gap-2 shadow-sm disabled:opacity-50 disabled:hover:bg-[#3B4FD8]"
            >
              {isLoading ? (
                <>
                  <Loader2 size={20} className="animate-spin" />
                  Ekleniyor...
                </>
              ) : (
                <>
                  <UserPlus size={20} />
                  Öğrenciyi Kaydet
                </>
              )}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}
