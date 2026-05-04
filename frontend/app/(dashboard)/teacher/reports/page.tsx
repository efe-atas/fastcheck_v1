import { BarChart2 } from 'lucide-react'

export default function ReportsPage() {
  return (
    <div className="flex flex-col items-center justify-center h-96 gap-4 text-center">
      <div className="w-16 h-16 bg-[#E8EDFF] rounded-2xl flex items-center justify-center">
        <BarChart2 size={28} className="text-[#2D5BFF]" />
      </div>
      <h1 className="text-xl font-semibold text-[#111827]">Raporlar</h1>
      <p className="text-[#6B7280] text-sm max-w-xs">
        Sınıf ve öğrenci performans raporları yakında burada görüntülenecek.
      </p>
    </div>
  )
}
