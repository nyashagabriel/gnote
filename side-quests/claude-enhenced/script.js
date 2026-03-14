// ─────────────────────────────────────────────────────────────
// GNOTE v3 — script.js
// Uniform interactions across all screens.
// ─────────────────────────────────────────────────────────────

// ── 1. Press feedback — spring physics ───────────────────────
const PRESS = [
  ".lab-card", ".primary-btn", ".secondary-btn", ".icon-btn",
  ".task-card", ".capture-card", ".nav-item", ".person-row",
  ".setting-row", ".d3-card", ".bento-card", ".ghost-card",
  ".pick-btn", ".wa-btn", ".role-option", ".cat-chip",
].join(", ");

document.querySelectorAll(PRESS).forEach((el) => {
  el.addEventListener("pointerdown", () => {
    el.style.transition = "transform 90ms cubic-bezier(0.4,0,0.2,1)";
    el.style.transform = "scale(0.965)";
  }, { passive: true });
  const up = () => {
    el.style.transition = "transform 260ms cubic-bezier(0.34,1.56,0.64,1)";
    el.style.transform = "";
  };
  el.addEventListener("pointerup", up);
  el.addEventListener("pointercancel", up);
  el.addEventListener("pointerleave", up);
});

// ── 2. Animated checkbox ──────────────────────────────────────
document.querySelectorAll(".checkbox").forEach((el) => {
  el.setAttribute("role", "checkbox");
  el.setAttribute("aria-checked", "false");
  el.setAttribute("tabindex", "0");

  const toggle = () => {
    const done = el.classList.toggle("done");
    el.setAttribute("aria-checked", done ? "true" : "false");
    if (done) {
      el.style.animation = "none";
      void el.offsetWidth; // reflow
      el.style.animation = "checkbox-pop 340ms cubic-bezier(0.34,1.56,0.64,1) forwards";
    }
  };

  el.addEventListener("click", toggle);
  el.addEventListener("keydown", (e) => {
    if (e.key === " " || e.key === "Enter") { e.preventDefault(); toggle(); }
  });
});

// ── 3. OTP — single 8-digit field ────────────────────────────
const singleOtp = document.querySelector(".otp-single");
if (singleOtp) {
  singleOtp.addEventListener("input", () => {
    const val = singleOtp.value.replace(/\D/g, "").slice(0, 8);
    singleOtp.value = val;

    // Progress bar
    const bar = document.getElementById("otp-bar");
    if (bar) {
      bar.style.width = (val.length / 8 * 100) + "%";
      bar.style.background = val.length === 8 ? "var(--success)" : "var(--orange)";
    }

    const btn = document.getElementById("otp-verify-btn");
    if (val.length === 8) {
      singleOtp.classList.add("ready");
      if (btn) btn.disabled = false;
    } else {
      singleOtp.classList.remove("ready");
      if (btn) btn.disabled = true;
    }
  });
}

// ── 4. Role / category toggle ─────────────────────────────────
document.querySelectorAll(".role-select, .relationship-select, .priority-select").forEach((group) => {
  group.querySelectorAll("button").forEach((btn) => {
    btn.addEventListener("click", () => {
      group.querySelectorAll("button").forEach((b) => b.classList.remove("active"));
      btn.classList.add("active");
    });
  });
});
document.querySelectorAll(".category-chips").forEach((group) => {
  group.querySelectorAll(".cat-chip").forEach((btn) => {
    btn.addEventListener("click", () => {
      group.querySelectorAll(".cat-chip").forEach((b) => b.classList.remove("active"));
      btn.classList.add("active");
    });
  });
});

// ── 5. Nav active state ───────────────────────────────────────
document.querySelectorAll(".nav-item").forEach((item) => {
  item.addEventListener("click", () => {
    item.closest(".phone-nav")
      ?.querySelectorAll(".nav-item")
      .forEach((n) => n.classList.remove("active"));
    item.classList.add("active");
  });
});
