'use client'

import { useState } from 'react'
import { Users, BookOpen, Loader2, Plus, Search, ChevronRight } from 'lucide-react'
import Link from 'next/link'
import useSWR from 'swr'
import { api } from '@/lib/api-client'

export default function ClassesPage() {
  const { data: classes, error, isLoading } = useSWR('teacherClasses', api.listTeacherClasses)
  const [search, setSearch] = useState('')

  if (isLoading) {
    return (
      <div className="flex items-center justify-center h-full min-h-[400px]">
        <Loader2 className="w-8 h-8 text-[#3B4FD8] animate-spin" />
      </div>
    )
  }

  if (error || !classes) {
    return <div className="text-red-500">Sınıflar yüklenemedi.</div>
  }

  const filtered = classes.filter(c => 
    (c.className || '').toLowerCase().includes((search || '').toLowerCase())
  )

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-semibold text-[#111827]">Sınıflarım</h1>
        <Link
          href="/teacher/classes/create"
          className="flex items-center gap-2 bg-[#3B4FD8] text-white px-4 py-2.5 rounded-xl text-sm font-semibold hover:bg-[#2D3DB8] transition-colors shadow-sm"
        >
          <Plus size={16} />
          Yeni Sınıf Ekle
        </Link>
      </div>

      {/* Hero Banner / Summary */}
      <div
        className="w-full rounded-2xl overflow-hidden relative"
        style={{ background: 'linear-gradient(135deg, #3B4FD8 0%, #1DB8A4 100%)', minHeight: 120 }}
      >
        <div className="absolute inset-0 opacity-10">
          <svg width="100%" height="100%" xmlns="http://www.w3.org/2000/svg">
            <defs>
              <pattern id="grid" width="40" height="40" patternUnits="userSpaceOnUse">
                <path d="M 40 0 L 0 0 0 40" fill="none" stroke="white" strokeWidth="1"/>
              </pattern>
            </defs>
            <rect width="100%" height="100%" fill="url(#grid)" />
          </svg>
        </div>
        <div className="relative p-6 flex items-center gap-4">
          <div className="w-12 h-12 bg-white/20 rounded-xl flex items-center justify-center shrink-0">
            <Users size={24} className="text-white" />
          </div>
          <div>
            <h2 className="text-white font-bold text-lg">Toplam {classes.length} Sınıf</h2>
            <p className="text-white/80 text-sm mt-1">Öğrencilerinizi ve sınavlarınızı sınıflar üzerinden yönetin</p>
          </div>
        </div>
      </div>

      {/* Search */}
      <div className="relative">
        <Search size={16} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-[#9CA3AF]" />
        <input
          type="text"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          placeholder="Sınıf ara..."
          className="w-full bg-white border border-[#DDE3F0] rounded-xl pl-10 pr-4 py-2.5 text-sm text-[#111827] placeholder:text-[#9CA3AF] focus:outline-none focus:border-[#3B4FD8] focus:ring-1 focus:ring-[#3B4FD8] shadow-sm"
        />
      </div>

      {/* Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {filtered.length === 0 ? (
          <div className="col-span-full text-center py-16 bg-white rounded-2xl border border-[#DDE3F0]">
            <Users size={36} className="text-[#9CA3AF] mx-auto mb-3" />
            <p className="text-[#0F1729] font-medium">Sınıf Bulunamadı</p>
            <p className="text-sm text-[#6B7A99] mt-1">Bu aramaya uygun sınıf yok veya henüz sınıf eklemediniz.</p>
          </div>
        ) : (
          filtered.map((cls) => (
            <Link key={cls.classId} href={`/teacher/classes/${cls.classId}`} className="block">
              <div className="bg-white rounded-2xl border border-[#DDE3F0] shadow-sm p-5 hover:shadow-md hover:border-[#3B4FD8]/30 transition-all group">
                <div className="flex items-start justify-between mb-4">
                  <div className="w-12 h-12 bg-[#E5EAFE] rounded-xl flex items-center justify-center group-hover:scale-105 transition-transform">
                    <Users size={22} className="text-[#3B4FD8]" />
                  </div>
                  <ChevronRight size={20} className="text-[#9CA3AF] group-hover:text-[#3B4FD8] transition-colors" />
                </div>
                <h3 className="font-bold text-[17px] text-[#0F1729] truncate">{cls.className}</h3>
                <p className="text-xs font-medium text-[#8A96B2] mt-1">Sınıf #{cls.classId}</p>
                <div className="mt-4 pt-4 border-t border-[#F1F5F9] flex items-center justify-between">
                  <span className="inline-flex items-center gap-1.5 text-xs font-semibold text-[#0BBFB0] bg-[#E1F5F2] rounded-full px-3 py-1.5">
                    <BookOpen size={14} />
                    {cls.examCount} Sınav
                  </span>
                </div>
              </div>
            </Link>
          ))
        )}
      </div>
    </div>
  )
}
