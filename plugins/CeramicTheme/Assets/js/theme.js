/*
 * CeramicTheme — лёгкий JS-слой темы Aeva (грузится хуком template:layout:js).
 * Только мягкие UX-доводки поверх Kanboard; функциональные обработчики
 * (drag&drop, модалки, шорткаты) НЕ переопределяем — переиспользуем родные.
 */
(function () {
  'use strict';

  /* ----------------------------------------------------------------
   * Закрытие модалки кликом по затемнённому фону.
   * Kanboard по умолчанию закрывает большие модалки только по ✕ / Esc
   * (чтобы случайный клик не потерял заполненную форму). Возвращаем
   * привычное «клик по фону = закрыть», но аккуратно: срабатывает только
   * если И нажатие, И отпускание мыши пришлись на сам оверлей. Так
   * выделение текста в поле с протягиванием за пределы окна не схлопнет
   * форму. Закрываем родной кнопкой Kanboard — без своей логики удаления.
   * ---------------------------------------------------------------- */
  var pressedOnOverlay = false;

  document.addEventListener('mousedown', function (e) {
    pressedOnOverlay = !!(e.target && e.target.id === 'modal-overlay');
  });

  document.addEventListener('mouseup', function (e) {
    var onOverlay = pressedOnOverlay && e.target && e.target.id === 'modal-overlay';
    pressedOnOverlay = false;
    if (!onOverlay) {
      return;
    }
    var closeBtn = document.getElementById('modal-close-button');
    if (closeBtn) {
      closeBtn.click(); // родной обработчик закрытия Kanboard
    } else if (window.KB && window.KB.modal && typeof window.KB.modal.close === 'function') {
      window.KB.modal.close();
    }
  });
})();
