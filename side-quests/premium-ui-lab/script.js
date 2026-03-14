document.querySelectorAll(".lab-card, .primary-btn, .secondary-btn, .icon-btn, .task-card, .capture-card").forEach((node) => {
  node.addEventListener("pointerdown", () => {
    node.style.transform = "scale(0.985)";
  });
  const release = () => {
    node.style.transform = "";
  };
  node.addEventListener("pointerup", release);
  node.addEventListener("pointercancel", release);
  node.addEventListener("pointerleave", release);
});

document.querySelectorAll(".checkbox").forEach((node) => {
  node.addEventListener("click", () => {
    node.classList.toggle("done");
  });
});
