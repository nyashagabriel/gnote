// ─────────────────────────────────────────────────────────────
// GNOTE UI LAB — script.js
//
// FIX 1: Press feedback needs CSS transition to feel physical.
//         Without it the scale is instantaneous — not tactile.
//         We inject the transition on first interaction rather
//         than relying on the stylesheet so the reveal animation
//         isn't fighting a transform transition on page load.
//
// FIX 2: Checkbox uses classList.toggle — now with a small
//         CSS keyframe so the done state "pops" rather than
//         snapping. Add aria-checked for accessibility.
//
// FIX 3: OTP inputs auto-advance and handle paste correctly.
//         Actual Supabase OTP is 8 digits (not 6 individual boxes).
//         The verify-otp.html screen uses a single 8-char field
//         which is the correct pattern — this block is kept for
//         any prototype that still uses individual boxes.
// ─────────────────────────────────────────────────────────────

// ── 1. Press feedback ────────────────────────────────────────
const PRESS_TARGETS =
  ".lab-card, .primary-btn, .secondary-btn, .icon-btn, .task-card, .capture-card, .nav-item, .person-row, .setting-row";

document.querySelectorAll(PRESS_TARGETS).forEach((node) => {
  // Inject transition once — avoids fighting the reveal animation
  node.addEventListener(
    "pointerdown",
    () => {
      node.style.transition = "transform 100ms cubic-bezier(0.4,0,0.2,1)";
      node.style.transform = "scale(0.97)";
    },
    { passive: true }
  );

  const release = () => {
    node.style.transition = "transform 200ms cubic-bezier(0.4,0,0.2,1)";
    node.style.transform = "";
  };

  node.addEventListener("pointerup", release);
  node.addEventListener("pointercancel", release);
  node.addEventListener("pointerleave", release);
});

// ── 2. Animated checkbox ──────────────────────────────────────
document.querySelectorAll(".checkbox").forEach((node) => {
  node.setAttribute("role", "checkbox");
  node.setAttribute("aria-checked", "false");
  node.setAttribute("tabindex", "0");

  const toggle = () => {
    const isDone = node.classList.toggle("done");
    node.setAttribute("aria-checked", isDone ? "true" : "false");

    // Pop animation on completion
    if (isDone) {
      node.style.animation = "none";
      // Force reflow
      void node.offsetWidth;
      node.style.animation = "checkbox-pop 300ms cubic-bezier(0.34,1.56,0.64,1) forwards";
    }
  };

  node.addEventListener("click", toggle);
  // Keyboard support
  node.addEventListener("keydown", (e) => {
    if (e.key === " " || e.key === "Enter") {
      e.preventDefault();
      toggle();
    }
  });
});

// ── 3. OTP individual-box auto-advance (legacy prototype use) ─
// Only runs if individual .otp-input boxes are present
const otpBoxes = [...document.querySelectorAll(".otp-input")];
if (otpBoxes.length > 1) {
  otpBoxes.forEach((input, i) => {
    input.addEventListener("input", (e) => {
      const val = e.target.value;
      // Allow only digits
      if (!/^\d*$/.test(val)) {
        e.target.value = "";
        return;
      }
      if (val.length >= 1 && i < otpBoxes.length - 1) {
        otpBoxes[i + 1].focus();
      }
      // Auto-submit when all filled
      if (otpBoxes.every((b) => b.value.length === 1)) {
        const code = otpBoxes.map((b) => b.value).join("");
        console.log("OTP ready:", code);
        // In real implementation: call verify(code)
      }
    });

    input.addEventListener("keydown", (e) => {
      if (e.key === "Backspace" && !e.target.value && i > 0) {
        otpBoxes[i - 1].focus();
      }
    });

    // Handle paste on first box
    if (i === 0) {
      input.addEventListener("paste", (e) => {
        e.preventDefault();
        const paste = (e.clipboardData || window.clipboardData)
          .getData("text")
          .replace(/\D/g, "")
          .slice(0, otpBoxes.length);
        paste.split("").forEach((char, idx) => {
          if (otpBoxes[idx]) otpBoxes[idx].value = char;
        });
        const next = otpBoxes[Math.min(paste.length, otpBoxes.length - 1)];
        next.focus();
      });
    }
  });
}

// ── 4. Single 8-digit OTP field auto-verify ──────────────────
const singleOtp = document.querySelector(".otp-single");
if (singleOtp) {
  singleOtp.addEventListener("input", () => {
    const val = singleOtp.value.replace(/\D/g, "").slice(0, 8);
    singleOtp.value = val;
    if (val.length === 8) {
      console.log("OTP ready:", val);
      // In real implementation: call verify(val)
      singleOtp.classList.add("ready");
    } else {
      singleOtp.classList.remove("ready");
    }
  });
}

// ── 5. Relationship type / Priority option toggles ────────────
document.querySelectorAll(".relationship-option, .priority-option").forEach((btn) => {
  btn.addEventListener("click", () => {
    const group = btn.closest(".relationship-select, .priority-select");
    if (!group) return;
    group.querySelectorAll(".relationship-option, .priority-option").forEach((b) =>
      b.classList.remove("active")
    );
    btn.classList.add("active");
  });
});

// ── 6. Nav active state ───────────────────────────────────────
document.querySelectorAll(".nav-item").forEach((item) => {
  item.addEventListener("click", () => {
    item.closest(".phone-nav")
      ?.querySelectorAll(".nav-item")
      .forEach((n) => n.classList.remove("active"));
    item.classList.add("active");
  });
});
