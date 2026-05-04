'use client'

import React from 'react'
import { ChevronLeft, RefreshCw, FileText, Grid3X3, Users, ChevronRight, Loader2 } from 'lucide-react'
import Link from 'next/link'
import useSWR from 'swr'
import { AvatarCircle } from '@/components/fastcheck/avatar-circle'
import { StatusBadge } from '@/components/fastcheck/status-badge'
import { api } from '@/lib/api-client'
import { getInitials } from '@/lib/exam-status'

export default function ExamReviewPage(props: {
  params: Promise<{ id: string }>
}) {
  const params = React.use(props.params)
  const id = params.id
  
  const { data: examData, error, isLoading, mutate } = useSWR(`examStatus-${id}`, () => api.getTeacherExamStatus(parseInt(id)))

  if (isLoading) {
    return (
      <div className="flex items-center justify-center h-full min-h-[400px]">
        <Loader2 className="w-8 h-8 text-[#2D5BFF] animate-spin" />
      </div>
    )
  }

  if (error || !examData) {
    return <div className="text-red-500">Sınav detayları yüklenemedi.</div>
  }

  const matchedStudents = examData.studentClusters.filter(c => !c.unmatched)
  const unmatchedClusters = examData.studentClusters.filter(c => c.unmatched)

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <Link
            href="/teacher/exams"
            className="w-9 h-9 bg-white rounded-xl flex items-center justify-center shadow-sm hover:bg-[#F0F2F8] transition-colors"
          >
            <ChevronLeft size={18} className="text-[#6B7280]" />
          </Link>
          <div>
            <h1 className="text-xl font-semibold text-[#111827]">{examData.title}</h1>
            <p className="text-sm text-[#6B7280]">Sınıf ID: {examData.classId} · {new Date().toLocaleDateString('tr-TR')}</p>
          </div>
        </div>
        <button className="w-9 h-9 bg-white rounded-xl flex items-center justify-center shadow-sm hover:bg-[#F0F2F8] transition-colors">
          <RefreshCw size={16} className="text-[#6B7280]" />
        </button>
      </div>

      {/* Sticky Info Bar */}
      <div className="bg-[#E1F5F2] rounded-xl px-5 py-3 flex items-center gap-4">
        <StatusBadge status={examData.examStatus === 'READY' ? 'Hazır' : examData.examStatus === 'PROCESSING' ? 'İşleniyor' : 'Taslak'} />
        <div className="flex items-center gap-1.5 text-sm text-[#6B7280]">
          <FileText size={14} className="text-[#1DB8A4]" />
          <span>{examData.images.length} sayfa</span>
        </div>
        <div className="flex items-center gap-1.5 text-sm text-[#6B7280]">
          <Grid3X3 size={14} className="text-[#1DB8A4]" />
          <span>{examData.questionCount} soru</span>
        </div>
        <div className="flex items-center gap-1.5 text-sm text-[#6B7280]">
          <Users size={14} className="text-[#1DB8A4]" />
          <span>{examData.students.length} öğrenci</span>
        </div>
      </div>

      {/* Student List */}
      <div className="space-y-3">
        {matchedStudents.map((cluster) => (
          <Link key={cluster.studentId} href={`/teacher/exams/${id}/review/${cluster.studentId}`}>
            <div className="bg-white rounded-2xl shadow-sm p-4 flex items-center gap-4 hover:shadow-md transition-shadow">
              <AvatarCircle initials={getInitials(cluster.studentName)} size="md" />
              <div className="flex-1 min-w-0">
                <p className="font-semibold text-[#111827] text-base">{cluster.studentName}</p>
                <p className="text-sm text-[#1DB8A4] mt-0.5">{cluster.matchingStatus === 'CONFIRMED' ? 'Eşleşti' : 'Otomatik Eşleşti'}</p>
              </div>
              <div className="text-right shrink-0">
                <p className="text-xl font-bold text-[#1DB8A4]">%{Math.round(cluster.scorePercentage || 0)}</p>
                <p className="text-[13px] text-[#9CA3AF]">{cluster.awardedPoints}/{cluster.maxPoints}</p>
              </div>
              <ChevronRight size={16} className="text-[#9CA3AF]" />
            </div>
          </Link>
        ))}
        {matchedStudents.length === 0 && (
          <div className="text-center py-8">
            <p className="text-[#6B7280] text-sm">Eşleşen öğrenci bulunamadı.</p>
          </div>
        )}
      </div>

      {/* Unmatched Papers Warning */}
      {unmatchedClusters.length > 0 && (
        <div className="bg-[#FFFBEB] rounded-2xl p-5 border border-[#FDE68A]/50 mt-8">
          <div className="flex items-center justify-between mb-3">
            <h3 className="font-semibold text-[#111827]">Atanmamış Kağıtlar ({unmatchedClusters.length})</h3>
            <StatusBadge status="Atama Bekliyor" />
          </div>
          {unmatchedClusters.map((cluster, idx) => (
            <div key={idx} className="mb-4 last:mb-0 pb-4 last:pb-0 border-b last:border-b-0 border-[#FDE68A]/50">
              <div className="flex items-center gap-4 text-sm text-[#6B7280]">
                <div className="flex items-center gap-1.5">
                  <FileText size={13} className="text-[#B45309]" />
                  <span>{cluster.pageCount} sayfa</span>
                </div>
                <div className="flex items-center gap-1.5">
                  <Grid3X3 size={13} className="text-[#B45309]" />
                  <span>{cluster.questionCount} soru</span>
                </div>
                <span>{cluster.awardedPoints} / {cluster.maxPoints} puan</span>
              </div>
              <div className="flex gap-3 mt-4 overflow-x-auto">
                {cluster.images.map((img) => (
                  <div key={img.imageId} className="bg-white rounded-xl p-2 w-24 flex flex-col items-center border border-[#E5E7EB] shrink-0">
                    <div className="w-full h-16 bg-[#F0F2F8] rounded-lg overflow-hidden mb-2">
                      <img
                        src={img.imageUrl}
                        alt={`Sayfa ${img.pageOrder}`}
                        className="w-full h-full object-cover"
                      />
                    </div>
                    <p className="text-[10px] font-medium text-[#111827]">Sayfa {img.pageOrder}</p>
                    <button className="mt-1 text-[10px] text-[#2D5BFF] hover:underline">Ata</button>
                  </div>
                ))}
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  )
}
