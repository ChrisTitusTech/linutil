// Site chrome: menus.
(() => {
  const root = document.documentElement;
  const $ = (selector, scope = document) => scope.querySelector(selector);
  const $$ = (selector, scope = document) => [...scope.querySelectorAll(selector)];

  // Narrow screens: the menu button shows the sidebar on docs pages and the site navigation elsewhere.
  const menuButton = $('.menu-toggle');
  const setMenu = (open) => {
    document.body.toggleAttribute('data-menu-open', open);
    menuButton.setAttribute('aria-expanded', String(open));
  };
  menuButton.addEventListener('click', () => setMenu(!document.body.hasAttribute('data-menu-open')));
  matchMedia('(min-width: 50em)').addEventListener('change', () => setMenu(false));

  // Header dropdowns open on hover from CSS; clicks and the keyboard go through .is-open.
  const dropdowns = $$('.nav-dropdown');
  const closeDropdowns = (except) => {
    for (const dropdown of dropdowns) {
      if (dropdown === except) continue;
      dropdown.classList.remove('is-open');
      $('button', dropdown).setAttribute('aria-expanded', 'false');
    }
  };
  for (const dropdown of dropdowns) {
    const button = $('button', dropdown);
    button.addEventListener('click', () => {
      const open = !dropdown.classList.contains('is-open');
      closeDropdowns(dropdown);
      dropdown.classList.toggle('is-open', open);
      button.setAttribute('aria-expanded', String(open));
    });
    // Tabbing out of a menu closes it, so it doesn't stay open over the page.
    dropdown.addEventListener('focusout', (event) => {
      if (!dropdown.contains(event.relatedTarget)) closeDropdowns();
    });
  }
  document.addEventListener('click', (event) => {
    if (!event.target.closest('.nav-dropdown')) closeDropdowns();
  });
  document.addEventListener('keydown', (event) => {
    if (event.key !== 'Escape') return;
    // Closing hides a focused menu link, so focus goes back to the button that opened it.
    const owner = document.activeElement?.closest('.nav-dropdown');
    if (owner) $('button', owner).focus();
    closeDropdowns();
    if (document.body.hasAttribute('data-menu-open')) {
      setMenu(false);
      menuButton.focus();
    }
  });

  // Long sidebars: scroll the current page's link into view.
  const sidebarPane = $('.sidebar-pane');
  const currentLink = sidebarPane && $('[aria-current="page"]', sidebarPane);
  if (currentLink && matchMedia('(min-width: 50em)').matches) {
    const pane = sidebarPane.getBoundingClientRect();
    const box = currentLink.getBoundingClientRect();
    if (box.bottom > pane.bottom) sidebarPane.scrollTop += box.top - pane.top - pane.height / 3;
  }
})();
