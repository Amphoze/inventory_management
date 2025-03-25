// Disable swipe navigation (browser history navigation).
window.addEventListener('wheel', function (event) {
    if (event.deltaX !== 0) {
        event.preventDefault();
    }
}, { passive: false });

window.addEventListener('touchstart', function (event) {
    event.preventDefault();
}, { passive: false });

window.addEventListener('touchmove', function (event) {
    event.preventDefault();
}, { passive: false });
