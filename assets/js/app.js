// TODOER — Phoenix LiveView app.js
// Handles LiveSocket, session hooks

import "phoenix_html"
import { Socket } from "phoenix"
import { LiveSocket } from "phoenix_live_view"
import topbar from "../vendor/topbar"

// ── Hooks ─────────────────────────────────────────────────────────────────────

const Hooks = {}

// Persist the user to sessionStorage so that on page-refresh
// the LiveView can read it back from the JS hook.
Hooks.SessionStore = {
  mounted() {
    this.handleEvent("save_user_session", ({ user_id, user_name, user_email }) => {
      sessionStorage.setItem("todoer_user", JSON.stringify({ id: user_id, name: user_name, email: user_email }))
    })
  }
}

// ── LiveSocket ────────────────────────────────────────────────────────────────

const csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
const liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {
    _csrf_token: csrfToken,
    // Pass stored user back to server on connect so mount() can read it
    user: (() => {
      try { return JSON.parse(sessionStorage.getItem("todoer_user") || "null") }
      catch { return null }
    })()
  },
  hooks: Hooks
})

// Show progress bar on live navigations and form submits
topbar.config({ barColors: { 0: "#16a34a" }, shadowColor: "rgba(0,0,0,.2)" })
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// Connect if there are any LiveViews on the page
liveSocket.connect()

// Expose liveSocket on window for web console debugging if desired
window.liveSocket = liveSocket
