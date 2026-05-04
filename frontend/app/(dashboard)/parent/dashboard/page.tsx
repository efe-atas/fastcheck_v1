'use client'

import Link from 'next/link'
import {
  ChevronRight,
  Users,
  CheckCircle,
  Clock,
  FileText,
  AlertCircle,
} from 'lucide-react'
import { cn } from '@/lib/utils'
import { type ParentStudentSummary } from '@/lib/api-client'
import { getStatusConfig, formatDate, getInitials } from '@/lib/exam-status'
import useSWR from 'swr'
import { api } from '@/lib/api-client'
import { Loader2 } from 'lucide-react'

const today = new Date()
const dateStr = today.toLocaleDateString('tr-TR', {
  weekday: 'long',
  day: 'numeric',
  month: 'long',
  year: 'numeric',
})

function capitalize(str: string) {
  return str.charAt(0).toUpperCase() + str.slice(1)
}

function StatusIcon({ status }: { status: string }) {
  switch (status) {
    case 'READY':
      return <CheckCircle size={20} className="text-[#1DB8A4]" />
    case 'PROCESSING':
      return <Clock size={20} className="text-[#F59E0B]" />
    case 'FAILED':
      return <AlertCircle size={20} className="text-[#EF4444]" />
    default:
      return <FileText size={20} className="text-[#9CA3AF]" />
  }
}

function StudentCard({ student }: { student: ParentStudentSummary }) {
  const initials = getInitials(student.fullName)
  const hasLatest = student.latestExamTitle != null
  const latestCfg = hasLatest ? getStatusConfig(student.latestExamStatus!) : null

  return (
    <Link
      href={`/parent/student/${student.studentId}/exams`}
      className="block"
    >
      <div className="bg-white rounded-2xl shadow-sm border border-[#E5E7EB] p-5 hover:shadow-md hover:border-[#2D5BFF]/30 transition-all">
        {/* Student header */}
        <div className="flex items-start gap-4 mb-4">
          <div className="w-12 h-12 rounded-xl bg-gradient-to-br from-[#2D5BFF] to-[#1A3FCC] flex items-center justify-center shrink-0">
            <span className="text-white font-bold text-base">{initials}</span>
          </div>
          <div className="flex-1 min-w-0">
            <h3 className="text-base font-bold text-[#111827]">{student.fullName}</h3>
            <p className="text-sm text-[#6B7280] truncate">{student.email}</p>
          </div>
          <ChevronRight size={18} className="text-[#9CA3AF] shrink-0 mt-1" />
        </div>

        {/* Stats */}
        <div className="grid grid-cols-2 gap-3 mb-4">
          <div className="bg-[#F0F2F8] rounded-xl p-3">
            <p className="text-xl font-bold text-[#111827]">{student.totalExams}</p>
            <p className="text-[12px] text-[#6B7280] mt-0.5">Toplam Sınav</p>
          </div>
          <div className="bg-[#E1F5F2] rounded-xl p-3">
            <p className="text-xl font-bold text-[#0D7A6A]">{student.readyExams}</p>
            <p className="text-[12px] text-[#0D7A6A]/70 mt-0.5">Hazır</p>
          </div>
        </div>

        {/* Latest exam */}
        {hasLatest && latestCfg ? (
          <div
            className={cn('rounded-xl p-3 flex items-center gap-3', latestCfg.bg)}
          >
            <StatusIcon status={student.latestExamStatus!} />
            <div className="flex-1 min-w-0">
              <p className="text-[14px] font-semibold text-[#111827] truncate">
                {student.latestExamTitle}
              </p>
              {student.latestExamCreatedAt && (
                <p className="text-[12px] text-[#6B7280]">
                  {formatDate(student.latestExamCreatedAt)}
                </p>
              )}
            </div>
            <span
              className={cn(
                'text-[11px] font-semibold px-2.5 py-1 rounded-full bg-white shrink-0',
                latestCfg.text,
              )}
            >
              {latestCfg.label}
            </span>
          </div>
        ) : (
          <p className="text-[13px] text-[#9CA3AF]">
            Bu öğrenci için henüz sınav yüklenmedi.
          </p>
        )}
      </div>
    </Link>
  )
}

export default function ParentDashboardPage() {
  const { data: dashboard, error, isLoading } = useSWR('parentDashboard', api.getParentDashboard)

  if (isLoading) {
    return (
      <div className="flex items-center justify-center h-full min-h-[400px]">
        <Loader2 className="w-8 h-8 text-[#2D5BFF] animate-spin" />
      </div>
    )
  }

  if (error || !dashboard) {
    return <div className="text-red-500">Gösterge paneli yüklenemedi.</div>
  }

  const students = dashboard.students || []

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-start justify-between">
        <div>
          <h1 className="text-2xl font-semibold text-[#111827]">
            Merhaba, Veli 👋
          </h1>
          <p className="text-[#6B7280] text-sm mt-1">{capitalize(dateStr)}</p>
        </div>
        <span className="inline-flex items-center rounded-full bg-[#1DB8A4] px-4 py-1.5 text-xs font-medium text-white tracking-wider">
          VELİ
        </span>
      </div>

      {/* Hero Banner */}
      <div
        className="w-full rounded-2xl overflow-hidden relative"
        style={{
          background: 'linear-gradient(135deg, #2D5BFF 0%, #1C2D9D 100%)',
          minHeight: 120,
        }}
      >
        <div className="absolute inset-0 opacity-10">
          <svg width="100%" height="100%" xmlns="http://www.w3.org/2000/svg">
            <defs>
              <pattern id="grid-p" width="40" height="40" patternUnits="userSpaceOnUse">
                <path d="M 40 0 L 0 0 0 40" fill="none" stroke="white" strokeWidth="1" />
              </pattern>
            </defs>
            <rect width="100%" height="100%" fill="url(#grid-p)" />
          </svg>
        </div>
        <div className="relative p-6 flex items-center gap-4">
          <div className="w-10 h-10 bg-white/20 rounded-xl flex items-center justify-center shrink-0">
            <Users size={20} className="text-white" />
          </div>
          <div>
            <p className="text-white font-bold text-base">
              {students.length} bağlı öğrenci
            </p>
            <p className="text-white/70 text-sm mt-0.5">
              Öğrencilerinizin sınav durumunu takip edin
            </p>
          </div>
        </div>
      </div>

      {/* Student Cards */}
      <section>
        <h2 className="text-base font-semibold text-[#111827] mb-4">Bağlı Öğrenciler</h2>
        {students.length === 0 ? (
          <div className="text-center py-16 bg-white rounded-2xl border border-[#E5E7EB]">
            <Users size={36} className="text-[#9CA3AF] mx-auto mb-3" />
            <p className="text-[#111827] font-medium">Bağlı Öğrenci Yok</p>
            <p className="text-[#6B7280] text-sm mt-1">
              Admin tarafından bağlanan öğrenciler burada listelenir.
            </p>
          </div>
        ) : (
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
            {students.map((student) => (
              <StudentCard key={student.studentId} student={student} />
            ))}
          </div>
        )}
      </section>
    </div>
  )
}
