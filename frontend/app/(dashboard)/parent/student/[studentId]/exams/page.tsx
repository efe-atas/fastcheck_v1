'use client'

import React, { useState } from 'react'
import Link from 'next/link'
import {
  ArrowLeft,
  Search,
  CheckCircle,
  Clock,
  FileText,
  AlertCircle,
  ChevronRight,
  BookOpen,
} from 'lucide-react'
import { cn } from '@/lib/utils'
import { getStatusConfig, formatDate, getInitials } from '@/lib/exam-status'
import useSWR from 'swr'
import { api } from '@/lib/api-client'
import { Loader2 } from 'lucide-react'

interface PageParams {
  studentId: string
}

const filters: { key: string | null; label: string }[] = [
  { key: null, label: 'Tümü' },
  { key: 'READY', label: 'Hazır' },
  { key: 'PROCESSING', label: 'İşleniyor' },
  { key: 'DRAFT', label: 'Taslak' },
  { key: 'FAILED', label: 'Hata' },
]

export default function ParentStudentExamsPage(props: { params: Promise<PageParams> }) {
  const params = React.use(props.params)
  const studentId = parseInt(params.studentId, 10)
  
  const { data: dashboard, isLoading: isLoadingDashboard } = useSWR('parentDashboard', api.getParentDashboard)
  const { data: pagedExams, isLoading: isLoadingExams } = useSWR(`parentStudentExams-${studentId}`, () => api.listParentStudentExams(studentId, 0, 100))

  const [activeFilter, setActiveFilter] = useState<string | null>(null)
  const [search, setSearch] = useState('')

  if (isLoadingDashboard || isLoadingExams) {
    return (
      <div className="flex items-center justify-center h-full min-h-[400px]">
        <Loader2 className="w-8 h-8 text-[#2D5BFF] animate-spin" />
      </div>
    )
  }

  const student = dashboard?.students.find((s) => s.studentId === studentId)
  const exams = pagedExams?.items || []

  const filtered = exams.filter((e) => {
    const matchesFilter = activeFilter == null || e.status === activeFilter
    const matchesSearch = e.title.toLowerCase().includes(search.toLowerCase())
    return matchesFilter && matchesSearch
  })

  const studentName = student?.fullName ?? `Öğrenci #${studentId}`
  const initials = student ? getInitials(student.fullName) : '??'

  return (
    <div className="space-y-6">
      {/* Back + Title */}
      <div className="flex items-center gap-3">
        <Link
          href="/parent/dashboard"
          className="w-9 h-9 bg-white rounded-xl flex items-center justify-center shadow-sm border border-[#E5E7EB] hover:bg-[#F0F2F8] transition-colors"
        >
          <ArrowLeft size={16} className="text-[#6B7280]" />
        </Link>
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-[#2D5BFF] to-[#1A3FCC] flex items-center justify-center shrink-0">
            <span className="text-white font-bold text-sm">{initials}</span>
          </div>
          <div>
            <h1 className="text-xl font-semibold text-[#111827]">{studentName}</h1>
            <p className="text-sm text-[#6B7280]">
              {student?.email ?? ''} · {exams.length} sınav
            </p>
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
          placeholder="Sınav ara..."
          className="w-full bg-white border border-[#E5E7EB] rounded-xl pl-10 pr-4 py-2.5 text-sm text-[#111827] placeholder:text-[#9CA3AF] focus:outline-none focus:border-[#2D5BFF] focus:ring-1 focus:ring-[#2D5BFF]"
        />
      </div>

      {/* Filter chips */}
      <div className="flex gap-2 flex-wrap">
        {filters.map((f) => (
          <button
            key={String(f.key)}
            onClick={() => setActiveFilter(f.key)}
            className={cn(
              'px-4 py-2 rounded-full text-sm font-semibold transition-colors border',
              activeFilter === f.key
                ? 'bg-[#2D5BFF] text-white border-[#2D5BFF]'
                : 'bg-white text-[#6B7280] border-[#E5E7EB] hover:border-[#2D5BFF] hover:text-[#2D5BFF]',
            )}
          >
            {f.label}
          </button>
        ))}
      </div>

      {/* Exam list */}
      <div className="space-y-3">
        {filtered.length === 0 ? (
          <div className="text-center py-16 bg-white rounded-2xl border border-[#E5E7EB]">
            <BookOpen size={36} className="text-[#9CA3AF] mx-auto mb-3" />
            <p className="text-[#111827] font-medium">Sınav bulunamadı</p>
            <p className="text-[#6B7280] text-sm mt-1">
              {activeFilter
                ? 'Bu filtreye uygun sınav yok.'
                : 'Öğrencinin sınıfında henüz sınav oluşturulmamış.'}
            </p>
          </div>
        ) : (
          filtered.map((exam) => {
            const cfg = getStatusConfig(exam.status)
            const isClickable = exam.status === 'READY'

            const content = (
              <div
                className={cn(
                  'bg-white rounded-2xl shadow-sm p-4 border border-[#E5E7EB] transition-all',
                  isClickable
                    ? 'hover:shadow-md hover:border-[#2D5BFF]/30 cursor-pointer'
                    : 'opacity-80',
                )}
              >
                <div className="flex items-center gap-4">
                  {/* Icon */}
                  <div
                    className={cn(
                      'w-12 h-12 rounded-xl flex items-center justify-center shrink-0 bg-gradient-to-br',
                      cfg.iconGradient,
                    )}
                  >
                    {exam.status === 'READY' ? (
                      <CheckCircle size={22} className="text-white" />
                    ) : exam.status === 'PROCESSING' ? (
                      <Clock size={22} className="text-white" />
                    ) : exam.status === 'FAILED' ? (
                      <AlertCircle size={22} className="text-white" />
                    ) : (
                      <FileText size={22} className="text-white" />
                    )}
                  </div>

                  <div className="flex-1 min-w-0">
                    <h3 className="text-base font-semibold text-[#111827] truncate">{exam.title}</h3>
                    <div className="flex items-center gap-2 mt-1">
                      <span
                        className={cn(
                          'inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium',
                          cfg.bg,
                          cfg.text,
                        )}
                      >
                        {cfg.label}
                      </span>
                      <span className="text-[12px] text-[#9CA3AF]">{formatDate(exam.createdAt)}</span>
                    </div>

                    {exam.scorePercentage != null && (
                      <div className="mt-2">
                        <div className="flex items-center justify-between mb-1">
                          <span className="text-[12px] text-[#6B7280]">Puan</span>
                          <span className="text-[12px] font-semibold text-[#111827]">
                            {exam.awardedPoints} / {exam.maxPoints}
                          </span>
                        </div>
                        <div className="h-1.5 bg-[#F3F4F6] rounded-full overflow-hidden">
                          <div
                            className="h-full bg-[#2D5BFF] rounded-full"
                            style={{ width: `${exam.scorePercentage}%` }}
                          />
                        </div>
                      </div>
                    )}
                  </div>

                  {isClickable ? (
                    <ChevronRight size={18} className="text-[#9CA3AF] shrink-0" />
                  ) : (
                    <span
                      className={cn(
                        'text-[11px] font-medium px-2 py-0.5 rounded-full shrink-0',
                        cfg.bg,
                        cfg.text,
                      )}
                    >
                      {cfg.label}
                    </span>
                  )}
                </div>
              </div>
            )

            return isClickable ? (
              <Link
                key={exam.examId}
                href={`/parent/exams/${exam.examId}?studentId=${studentId}`}
                className="block"
              >
                {content}
              </Link>
            ) : (
              <div key={exam.examId}>{content}</div>
            )
          })
        )}
      </div>
    </div>
  )
}
