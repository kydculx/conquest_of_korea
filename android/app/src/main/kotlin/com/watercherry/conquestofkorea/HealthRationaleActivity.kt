package com.watercherry.conquestofkorea

import android.app.Activity
import android.content.Intent
import android.graphics.Color
import android.net.Uri
import android.os.Bundle
import android.widget.Button
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
import java.util.Locale

class HealthRationaleActivity : Activity() {
    private val policyBaseUrl = "https://jjim.vercel.app/privacy"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val korean = Locale.getDefault().language.startsWith("ko")
        val background = Color.parseColor("#0E1520")
        val headingColor = Color.parseColor("#E6EDF7")
        val bodyColor = Color.parseColor("#A9B4C4")
        val accent = Color.parseColor("#22D3EE")
        val secondaryButton = Color.parseColor("#1B2735")
        val density = resources.displayMetrics.density

        fun dp(value: Int): Int = (value * density).toInt()

        fun heading(text: String): TextView = TextView(this).apply {
            this.text = text
            setTextColor(headingColor)
            textSize = 20f
            setPadding(0, 0, 0, dp(12))
        }

        fun body(text: String): TextView = TextView(this).apply {
            this.text = text
            setTextColor(bodyColor)
            textSize = 14f
            setLineSpacing(dp(4).toFloat(), 1.0f)
            setPadding(0, 0, 0, dp(16))
        }

        fun actionButton(text: String, color: Int, textColor: Int, onClick: () -> Unit): Button =
            Button(this).apply {
                this.text = text
                setBackgroundColor(color)
                setTextColor(textColor)
                setOnClickListener { onClick() }
            }

        val content = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setBackgroundColor(background)
            setPadding(dp(24), dp(32), dp(24), dp(24))
            addView(
                heading(
                    if (korean) "Health Connect 권한 안내"
                    else "Health Connect permissions"
                )
            )
            addView(
                body(
                    if (korean)
                        "찜! 모험은 Health Connect에서 걸음 수(Steps)를 읽기 전용으로 가져옵니다.\n\n" +
                            "· 수집 항목: 오늘 걸음 수, 최근 30일 걸음 수 기록\n" +
                            "· 이용 목적: 게임 화면의 걸음 수 표시, '월간 이동' 기록, 홈 화면 위젯\n" +
                            "· 이용자 혜택: 실제 이동량이 게임 진행과 영토 확보에 반영됩니다\n" +
                            "· 보관/삭제: 계정과 연결되어 서버(Supabase)에 저장되며, 회원 탈퇴 시 삭제됩니다\n" +
                            "· 제3자 제공: 없음. 광고·마케팅·데이터 판매에 사용하지 않습니다\n" +
                            "· 권한 철회: Health Connect > 앱 권한에서 언제든지 해제할 수 있습니다\n\n" +
                            "걸음 수 외의 데이터(심박수, 수면, 거리, 걸음 케이던스 등)는 접근하지 않습니다."
                    else
                        "Dibs! Adventure reads your step count from Health Connect in read-only mode.\n\n" +
                            "· Data read: today's steps and the last 30 days of step records\n" +
                            "· Purpose: show your step count in the game, monthly movement records, home screen widget\n" +
                            "· Benefit: your real-world walking drives in-game progress and territory capture\n" +
                            "· Storage/deletion: stored with your account on our server (Supabase) and deleted when you delete your account\n" +
                            "· Sharing: none. Never used for advertising, marketing, or selling data\n" +
                            "· Revocation: you can revoke access anytime in Health Connect > App permissions\n\n" +
                            "We do not access any other data types such as heart rate, sleep, distance, or steps cadence."
                )
            )
            addView(
                actionButton(
                    if (korean) "개인정보처리방침 보기" else "Open privacy policy",
                    accent,
                    Color.parseColor("#08131C")
                ) { openPolicy(korean) }
            )
            addView(
                actionButton(
                    if (korean) "닫기" else "Close",
                    secondaryButton,
                    headingColor
                ) { finish() }
            )
        }

        setContentView(
            ScrollView(this).apply {
                setBackgroundColor(background)
                addView(
                    content,
                    LinearLayout.LayoutParams(
                        LinearLayout.LayoutParams.MATCH_PARENT,
                        LinearLayout.LayoutParams.WRAP_CONTENT
                    )
                )
            }
        )
    }

    private fun openPolicy(korean: Boolean) {
        val url = if (korean) "$policyBaseUrl?lang=ko" else "$policyBaseUrl?lang=en"
        startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(url)))
    }
}
