'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { Eye, EyeOff, CheckSquare } from 'lucide-react'
import { cn } from '@/lib/utils'
import { api, decodeJwt } from '@/lib/api-client'

export default function LoginPage() {
  const router = useRouter()
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [showPassword, setShowPassword] = useState(false)
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setError('')
    if (!email || !password) {
      setError('E-posta veya şifre hatalı')
      return
    }
    setLoading(true)
    try {
      const response = await api.login({ email, password })
      localStorage.setItem('access_token', response.accessToken)
      localStorage.setItem('refresh_token', response.refreshToken)

      // Decode the JWT to extract the role claim set by the backend
      const payload = decodeJwt(response.accessToken)
      const role: string = payload?.role ?? ''
      localStorage.setItem('user_role', role)

      // Route based on the actual role value stored in the JWT
      if (role === 'ROLE_STUDENT' || role === 'STUDENT') {
        router.push('/student/dashboard')
      } else if (role === 'ROLE_PARENT' || role === 'PARENT') {
        router.push('/parent/dashboard')
      } else {
        // TEACHER, ADMIN, or any unrecognized role → teacher dashboard
        router.push('/teacher/dashboard')
      }
    } catch (err: any) {
      setError('Giriş başarısız. Lütfen bilgilerinizi kontrol edin.')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="min-h-screen flex">
      {/* Left Panel */}
      <div
        className="hidden lg:flex lg:w-2/5 flex-col justify-between p-12 relative overflow-hidden"
        style={{ background: 'linear-gradient(160deg, #2D5BFF 0%, #1A3FCC 100%)' }}
      >
        {/* Grid Pattern */}
        <div className="absolute inset-0 opacity-[0.08]">
          <svg width="100%" height="100%" xmlns="http://www.w3.org/2000/svg">
            <defs>
              <pattern id="grid" width="48" height="48" patternUnits="userSpaceOnUse">
                <path d="M 48 0 L 0 0 0 48" fill="none" stroke="white" strokeWidth="1"/>
              </pattern>
            </defs>
            <rect width="100%" height="100%" fill="url(#grid)" />
          </svg>
        </div>

        {/* Logo */}
        <div className="relative flex items-center gap-3">
          <div className="w-10 h-10 bg-white/20 rounded-xl flex items-center justify-center">
            <CheckSquare size={22} className="text-white" />
          </div>
          <span className="text-white font-bold text-xl">FastCheck</span>
        </div>

        {/* Center Content */}
        <div className="relative">
          <h2 className="text-4xl font-bold text-white leading-tight mb-4">
            Sınavları yapay zeka ile değerlendir
          </h2>
          <p className="text-white/60 text-lg leading-relaxed">
            Kağıtları saniyeler içinde dijitalleştir
          </p>
          <div className="mt-8 flex flex-col gap-3">
            {[
              'OCR ile el yazısı tanıma',
              'Otomatik puanlama ve rubrik eşleştirme',
              'Anında öğrenci ve veli bilgilendirme',
            ].map((item) => (
              <div key={item} className="flex items-center gap-3">
                <div className="w-5 h-5 rounded-full bg-white/20 flex items-center justify-center shrink-0">
                  <svg className="w-3 h-3 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2.5} d="M5 13l4 4L19 7" />
                  </svg>
                </div>
                <span className="text-white/80 text-sm">{item}</span>
              </div>
            ))}
          </div>
        </div>

        {/* Bottom */}
        <div className="relative">
          <p className="text-white/40 text-sm">&copy; 2026 FastCheck. Tüm hakları saklıdır.</p>
        </div>
      </div>

      {/* Right Panel */}
      <div className="flex-1 flex items-center justify-center bg-white p-8">
        <div className="w-full max-w-md">
          {/* Mobile Logo */}
          <div className="flex items-center gap-2 mb-8 lg:hidden">
            <div className="w-8 h-8 bg-[#2D5BFF] rounded-xl flex items-center justify-center">
              <CheckSquare size={18} className="text-white" />
            </div>
            <span className="text-[#111827] font-bold text-lg">FastCheck</span>
          </div>

          <h1 className="text-3xl font-semibold text-[#111827] mb-2">Hoş Geldiniz</h1>
          <p className="text-[#6B7280] mb-8">FastCheck hesabınıza giriş yapın</p>

          <form onSubmit={handleSubmit} className="space-y-5">
            {/* Email */}
            <div>
              <label className="block text-sm font-medium text-[#374151] mb-1.5">E-posta</label>
              <input
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="ornek@okul.edu.tr"
                className={cn(
                  'w-full border rounded-xl px-4 py-3 text-sm text-[#111827] placeholder:text-[#9CA3AF] focus:outline-none focus:ring-2 focus:ring-[#2D5BFF]/30 transition-colors',
                  error ? 'border-red-400 bg-red-50' : 'border-[#E5E7EB] bg-white focus:border-[#2D5BFF]'
                )}
              />
            </div>

            {/* Password */}
            <div>
              <label className="block text-sm font-medium text-[#374151] mb-1.5">Şifre</label>
              <div className="relative">
                <input
                  type={showPassword ? 'text' : 'password'}
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder="••••••••"
                  className={cn(
                    'w-full border rounded-xl px-4 py-3 pr-11 text-sm text-[#111827] placeholder:text-[#9CA3AF] focus:outline-none focus:ring-2 focus:ring-[#2D5BFF]/30 transition-colors',
                    error ? 'border-red-400 bg-red-50' : 'border-[#E5E7EB] bg-white focus:border-[#2D5BFF]'
                  )}
                />
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  className="absolute right-3.5 top-1/2 -translate-y-1/2 text-[#9CA3AF] hover:text-[#6B7280]"
                >
                  {showPassword ? <EyeOff size={18} /> : <Eye size={18} />}
                </button>
              </div>
              {error && <p className="text-red-500 text-xs mt-1.5">{error}</p>}
            </div>

            {/* Submit */}
            <button
              type="submit"
              disabled={loading}
              className="w-full bg-[#2D5BFF] text-white py-3.5 rounded-xl text-sm font-semibold hover:bg-[#1A3FCC] transition-colors disabled:opacity-70 disabled:cursor-not-allowed flex items-center justify-center gap-2 h-12"
            >
              {loading ? (
                <>
                  <svg className="animate-spin w-4 h-4" fill="none" viewBox="0 0 24 24">
                    <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"/>
                    <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z"/>
                  </svg>
                  Giriş yapılıyor...
                </>
              ) : (
                'Giriş Yap'
              )}
            </button>
          </form>

          <p className="text-center text-xs text-[#9CA3AF] mt-6">
            Demo için herhangi bir e-posta ve şifre girin
          </p>
        </div>
      </div>
    </div>
  )
}
