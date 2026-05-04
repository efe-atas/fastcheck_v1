'use client'

import { use, useState } from 'react'
import { Users, FileText, Plus, ChevronLeft, Loader2, Mail } from 'lucide-react'
import Link from 'next/link'
import useSWR from 'swr'
import { api } from '@/lib/api-client'
import { getStatusConfig, formatDate } from '@/lib/exam-status'
import { cn } from '@/lib/utils'

export default function ClassDetailPage({ params }: { params: Promise<{ id: string }> }) {
  const resolvedParams = use(params)
  const classId = parseInt(resolvedParams.id, 10)

  const { data: classes, isLoading: isClassesLoading } = useSWR('teacherClasses', api.listTeacherClasses)
  const { data: exams, isLoading: isExamsLoading } = useSWR(`classExams-${classId}`, () => api.listClassExams(classId))
  const { data: students, isLoading: isStudentsLoading } = useSWR(`classStudents-${classId}`, () => api.listClassStudents(classId))

  const [activeTab, setActiveTab] = useState<'Öğrenciler' | 'Sınavlar'>('Öğrenciler')

  const isLoading = isClassesLoading || isExamsLoading || isStudentsLoading

  if (isLoading) {
    return (
      <div className="flex items-center justify-center h-full min-h-[400px]">
        <Loader2 className="w-8 h-8 text-[#3B4FD8] animate-spin" />
      </div>
    )
  }

  const currentClass = classes?.find((c) => c.classId === classId)

  if (!currentClass) {
    return (
      <div className="text-center py-16">
        <p className="text-red-500 font-medium">Sınıf bulunamadı.</p>
        <Link href="/teacher/classes" className="text-[#3B4FD8] mt-2 inline-block">Sınıflarıma Dön</Link>
      </div>
    )
  }

  const studentsList = students?.items || []
  const examsList = exams || []

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center gap-3">
        <Link href="/teacher/classes" className="w-10 h-10 bg-white border border-[#DDE3F0] rounded-xl flex items-center justify-center text-[#6B7A99] hover:text-[#0F1729] hover:bg-[#F8FAFC] transition-colors">
          <ChevronLeft size={20} />
        </Link>
        <div>
          <h1 className="text-2xl font-bold text-[#0F1729]">{currentClass.className}</h1>
          <p className="text-sm text-[#8A96B2]">Sınıf ID: {classId}</p>
        </div>
      </div>

      {/* Hero Stats */}
      <div className="grid grid-cols-2 gap-4">
        <div className="bg-white rounded-2xl border border-[#DDE3F0] p-5 shadow-sm flex items-center gap-4">
          <div className="w-12 h-12 bg-[#E1F5F2] rounded-xl flex items-center justify-center shrink-0">
            <Users size={22} className="text-[#0BBFB0]" />
          </div>
          <div>
            <p className="text-3xl font-bold text-[#0F1729]">{studentsList.length}</p>
            <p className="text-xs text-[#6B7A99] font-medium mt-0.5">Kayıtlı Öğrenci</p>
          </div>
        </div>
        <div className="bg-white rounded-2xl border border-[#DDE3F0] p-5 shadow-sm flex items-center gap-4">
          <div className="w-12 h-12 bg-[#E5EAFE] rounded-xl flex items-center justify-center shrink-0">
            <FileText size={22} className="text-[#3B4FD8]" />
          </div>
          <div>
            <p className="text-3xl font-bold text-[#0F1729]">{examsList.length}</p>
            <p className="text-xs text-[#6B7A99] font-medium mt-0.5">Toplam Sınav</p>
          </div>
        </div>
      </div>

      {/* Action Buttons */}
      <div className="flex flex-col sm:flex-row gap-3">
        <Link
          href={`/teacher/classes/${classId}/add-student`}
          className="flex-1 bg-white border border-[#3B4FD8] text-[#3B4FD8] px-4 py-3 rounded-xl text-[15px] font-bold hover:bg-[#E5EAFE] transition-colors flex items-center justify-center gap-2"
        >
          <Plus size={18} />
          Öğrenci Ekle
        </Link>
        <Link
          href={`/teacher/exams/create?classId=${classId}`}
          className="flex-1 bg-[#3B4FD8] text-white px-4 py-3 rounded-xl text-[15px] font-bold hover:bg-[#2D3DB8] transition-colors flex items-center justify-center gap-2 shadow-sm"
        >
          <Plus size={18} />
          Yeni Sınav Oluştur
        </Link>
      </div>

      {/* Tabs */}
      <div className="bg-[#E3E8F3] rounded-2xl p-1 inline-flex gap-1 w-full mt-2">
        {(['Öğrenciler', 'Sınavlar'] as const).map((tab) => (
          <button
            key={tab}
            onClick={() => setActiveTab(tab)}
            className={cn(
              'flex-1 flex items-center justify-center gap-2 py-2.5 px-4 rounded-xl text-[15px] font-bold transition-all duration-150',
              activeTab === tab
                ? 'bg-white text-[#3B4FD8] shadow-sm'
                : 'text-[#6B7A99] hover:text-[#0F1729]'
            )}
          >
            {tab === 'Öğrenciler' ? <Users size={16} /> : <FileText size={16} />}
            {tab}
          </button>
        ))}
      </div>

      {/* Tab Content */}
      <div className="mt-4">
        {activeTab === 'Öğrenciler' && (
          <div className="space-y-3">
            {studentsList.length === 0 ? (
              <div className="text-center py-16 bg-white rounded-2xl border border-[#DDE3F0]">
                <Users size={36} className="text-[#9CA3AF] mx-auto mb-3" />
                <p className="text-[#0F1729] font-medium">Öğrenci Bulunmuyor</p>
                <p className="text-sm text-[#6B7A99] mt-1">Bu sınıfa henüz öğrenci eklemediniz.</p>
              </div>
            ) : (
              studentsList.map((student) => (
                <div key={student.userId} className="bg-white rounded-2xl border border-[#DDE3F0] p-4 flex items-center gap-4 hover:shadow-sm transition-shadow">
                  <div className="w-12 h-12 bg-gradient-to-br from-[#3B4FD8] to-[#2D3DB8] rounded-xl flex items-center justify-center shrink-0">
                    <span className="text-white font-bold text-lg">
                      {student.fullName.substring(0, 2).toUpperCase()}
                    </span>
                  </div>
                  <div className="flex-1 min-w-0">
                    <h3 className="font-bold text-[16px] text-[#0F1729] truncate">{student.fullName}</h3>
                    <div className="flex items-center gap-1.5 text-[#6B7A99] mt-1">
                      <Mail size={12} />
                      <p className="text-[13px] truncate">{student.email}</p>
                    </div>
                  </div>
                </div>
              ))
            )}
          </div>
        )}

        {activeTab === 'Sınavlar' && (
          <div className="space-y-3">
            {examsList.length === 0 ? (
              <div className="text-center py-16 bg-white rounded-2xl border border-[#DDE3F0]">
                <FileText size={36} className="text-[#9CA3AF] mx-auto mb-3" />
                <p className="text-[#0F1729] font-medium">Sınav Bulunmuyor</p>
                <p className="text-sm text-[#6B7A99] mt-1">Bu sınıf için henüz sınav oluşturmadınız.</p>
              </div>
            ) : (
              examsList.map((exam) => {
                const cfg = getStatusConfig(exam.status)
                return (
                  <Link key={exam.examId} href={`/teacher/exams/${exam.examId}/review`} className="block">
                    <div className="bg-white rounded-2xl border border-[#DDE3F0] shadow-sm p-4 hover:shadow-md transition-shadow">
                      <div className="flex items-start justify-between">
                        <div className="flex-1 min-w-0 pr-4">
                          <h3 className="font-bold text-[16px] text-[#0F1729] truncate">{exam.title}</h3>
                          <p className="text-[12px] text-[#6B7A99] mt-1">{formatDate(exam.createdAt)}</p>
                        </div>
                        <span className={cn('text-[11px] font-bold px-2.5 py-1 rounded-full shrink-0', cfg.bg, cfg.text)}>
                          {cfg.label}
                        </span>
                      </div>
                    </div>
                  </Link>
                )
              })
            )}
          </div>
        )}
      </div>
    </div>
  )
}
