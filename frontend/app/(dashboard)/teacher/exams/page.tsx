'use client'

import { useState } from 'react'
import { Plus, Search, CheckCircle2, Clock3, FileStack, Loader2, ChevronRight, Calendar, BookOpen } from 'lucide-react'
import Link from 'next/link'
import useSWR from 'swr'
import { cn } from '@/lib/utils'
import { useRouter } from 'next/navigation'
import { api } from '@/lib/api-client'
import { isCompleted, isDraft, isActive, getStatusConfig, formatDate } from '@/lib/exam-status'

type Tab = 'Aktif' | 'Tamamlandı' | 'Taslak'

const TABS: Tab[] = ['Aktif', 'Tamamlandı', 'Taslak']

const TAB_ICONS: Record<Tab, React.ReactNode> = {
  'Aktif': <Clock3 size={14} />,
  'Tamamlandı': <CheckCircle2 size={14} />,
  'Taslak': <FileStack size={14} />,
}

const fetchAllExams = async () => {
  const classes = await api.listTeacherClasses()
  const allExams: any[] = []
  for (const c of classes) {
    const exams = await api.listClassExams(c.classId)
    allExams.push(...exams.map((e) => ({ ...e, className: c.className })))
  }
  return allExams.sort(
    (a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime()
  )
}

function filterByTab(exams: any[], tab: Tab) {
  // Mobilin _filteredExams() mantığıyla birebir uyumlu:
  // Aktif      = ne tamamlandı ne taslak  (PROCESSING, FAILED vb.)
  // Tamamlandı = READY | DONE | COMPLETED
  // Taslak     = DRAFT | PENDING
  if (tab === 'Aktif') return exams.filter((e) => isActive(e.status))
  if (tab === 'Tamamlandı') return exams.filter((e) => isCompleted(e.status))
  return exams.filter((e) => isDraft(e.status))
}

export default function ExamsPage() {
  const router = useRouter()
  const { data: allExams, isLoading } = useSWR('teacherAllExams', fetchAllExams)
  const [activeTab, setActiveTab] = useState<Tab>('Aktif')
  const [search, setSearch] = useState('')

  const exams = allExams || []

  const filtered = filterByTab(exams, activeTab).filter(
    (exam) =>
      exam.title.toLowerCase().includes(search.toLowerCase()) ||
      exam.className.toLowerCase().includes(search.toLowerCase())
  )

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-semibold text-[#111827]">Sınavlar</h1>
        <Link
          href="/teacher/exams/create"
          className="flex items-center gap-2 bg-[#3B4FD8] text-white px-4 py-2.5 rounded-xl text-sm font-semibold hover:bg-[#2D3DB8] transition-colors"
        >
          <Plus size={16} />
          Yeni Sınav Oluştur
        </Link>
      </div>

      {/* Tab Bar — mobil _StatusTabs ile birebir */}
      <div className="bg-[#E3E8F3] rounded-2xl p-1 inline-flex gap-1 w-full">
        {TABS.map((tab) => (
          <button
            key={tab}
            onClick={() => setActiveTab(tab)}
            className={cn(
              'flex-1 flex items-center justify-center gap-1.5 py-2 px-3 rounded-xl text-sm font-semibold transition-all duration-150',
              activeTab === tab
                ? 'bg-white text-[#3B4FD8] shadow-sm'
                : 'text-[#6B7A99] hover:text-[#0F1729]'
            )}
          >
            {TAB_ICONS[tab]}
            {tab}
          </button>
        ))}
      </div>

      {/* Search */}
      <div className="relative">
        <Search size={16} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-[#9CA3AF]" />
        <input
          type="text"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          placeholder="Sınav veya sınıf ara..."
          className="w-full bg-white border border-[#E5E7EB] rounded-xl pl-10 pr-4 py-2.5 text-sm text-[#111827] placeholder:text-[#9CA3AF] focus:outline-none focus:border-[#3B4FD8] focus:ring-1 focus:ring-[#3B4FD8]"
        />
      </div>

      {/* Create CTA — mobilin AppInlineCta ile aynı */}
      <Link href="/teacher/exams/create" className="block">
        <div className="bg-white rounded-2xl shadow-sm p-4 flex items-center gap-4 hover:shadow-md transition-shadow border border-[#DDE3F0]">
          <div className="w-10 h-10 bg-[#E5EAFE] rounded-xl flex items-center justify-center shrink-0">
            <Plus size={20} className="text-[#3B4FD8]" />
          </div>
          <div className="flex-1">
            <p className="font-semibold text-[#0F1729]">Yeni Sınav Oluştur</p>
            <p className="text-sm text-[#6B7A99]">Sınıf seçip hızlıca sınav ekleyin</p>
          </div>
          <ChevronRight size={18} className="text-[#9CA3AF]" />
        </div>
      </Link>

      {/* Exam List */}
      <div className="space-y-3">
        {isLoading ? (
          <div className="flex justify-center py-12">
            <Loader2 className="w-8 h-8 animate-spin text-[#3B4FD8]" />
          </div>
        ) : filtered.length === 0 ? (
          <div className="text-center py-16 bg-white rounded-2xl border border-[#DDE3F0]">
            <BookOpen size={36} className="text-[#9CA3AF] mx-auto mb-3" />
            <p className="text-[#0F1729] font-medium">Sınav Bulunamadı</p>
            <p className="text-sm text-[#6B7A99] mt-1">
              {activeTab === 'Aktif'
                ? 'Şu an işleniyor ya da hata alan sınav yok.'
                : activeTab === 'Tamamlandı'
                ? 'Henüz tamamlanmış sınav bulunmuyor.'
                : 'Taslak veya bekleyen sınav yok.'}
            </p>
          </div>
        ) : (
          filtered.map((exam) => {
            const cfg = getStatusConfig(exam.status)
            const accentColor = cfg.isDone ? '#0BBFB0' : '#3B4FD8'
            return (
              <div
                key={exam.examId}
                className="bg-white rounded-2xl border border-[#DDE3F0] shadow-sm overflow-hidden hover:shadow-md transition-shadow"
              >
                <div className="flex">
                  {/* Left color bar — mobilin _ExamOverviewCard sol çubuğu */}
                  <div
                    className="w-1 shrink-0 rounded-l-2xl"
                    style={{ backgroundColor: accentColor }}
                  />
                  <div className="flex-1 p-4 flex gap-3">
                    <div className="flex-1 min-w-0 space-y-1.5">
                      {/* Class + status badges */}
                      <div className="flex items-center gap-2 flex-wrap">
                        <span
                          className="text-[10px] font-bold px-2 py-0.5 rounded-full"
                          style={{
                            backgroundColor: `${accentColor}1F`,
                            color: accentColor,
                          }}
                        >
                          {exam.className.toUpperCase()}
                        </span>
                        <span
                          className={cn(
                            'text-[10px] font-bold px-2 py-0.5 rounded-full',
                            cfg.bg,
                            cfg.text
                          )}
                        >
                          {cfg.label}
                        </span>
                      </div>
                      {/* Title */}
                      <p className="text-[15px] font-bold text-[#0F1729] truncate">{exam.title}</p>
                      {/* Date */}
                      <div className="flex items-center gap-1.5 text-[#6B7A99]">
                        <Calendar size={11} />
                        <span className="text-[11px]">{formatDate(exam.createdAt)}</span>
                      </div>
                    </div>
                    {/* Right action */}
                    <div className="flex flex-col items-center justify-center gap-2 shrink-0">
                      <div
                        className="w-11 h-11 rounded-xl flex items-center justify-center"
                        style={{ backgroundColor: `${accentColor}1A` }}
                      >
                        {cfg.isDone ? (
                          <CheckCircle2 size={20} style={{ color: accentColor }} />
                        ) : (
                          <Clock3 size={20} style={{ color: accentColor }} />
                        )}
                      </div>
                      <button
                        onClick={() => router.push(`/teacher/exams/${exam.examId}/review`)}
                        className="flex items-center gap-0.5 text-xs font-bold"
                        style={{ color: accentColor }}
                      >
                        Detaylar
                        <ChevronRight size={14} style={{ color: accentColor }} />
                      </button>
                    </div>
                  </div>
                </div>
              </div>
            )
          })
        )}
      </div>
    </div>
  )
}
