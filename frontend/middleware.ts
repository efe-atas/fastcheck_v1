import { NextResponse } from 'next/server'
import type { NextRequest } from 'next/server'

export function middleware(request: NextRequest) {
  // Gelen isteğin header'larını kopyalıyoruz
  const requestHeaders = new Headers(request.headers)

  // Spring Boot'un CORS filtresini (SecurityConfig) mutlu etmek için
  // tarayıcıdan gelen Origin header'ını production domaini ile eziyoruz
  requestHeaders.set('Origin', 'https://efeatas.dev')

  // İsteği yeni header'larla Next.js proxy'sine (rewrites) iletiyoruz
  return NextResponse.next({
    request: {
      headers: requestHeaders,
    },
  })
}

// Sadece /api/ ile başlayan isteklere müdahale etmesi için matcher ekliyoruz
export const config = {
  matcher: '/api/:path*',
}
