import { ParentSidebar } from '@/components/fastcheck/parent-sidebar'

export default function ParentLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <div className="flex min-h-screen">
      <ParentSidebar />
      <main className="flex-1 ml-[280px] overflow-x-hidden">
        <div className="max-w-[1400px] w-full mx-auto px-6 py-8 lg:px-10">
          {children}
        </div>
      </main>
    </div>
  )
}
