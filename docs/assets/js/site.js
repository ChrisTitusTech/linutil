// Site chrome: menus, table of contents, and code copy buttons.
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

  setUpToc();

  // Copy buttons: code blocks copy their code, the rest carry the text in data-copy.
  document.addEventListener('click', async (event) => {
    const button = event.target.closest('.code-copy, .copy-button');
    if (!button) return;
    const text = button.dataset.copy ?? $('pre code', button.parentElement).innerText.replace(/\n$/, '');
    try {
      await navigator.clipboard.writeText(text);
      button.textContent = '[copied]';
    } catch {
      button.textContent = '[failed]';
    }
    button.classList.add('is-copied');
    setTimeout(() => {
      button.textContent = '[copy]';
      button.classList.remove('is-copied');
    }, 2000);
  });

  // Highlights the last heading that has scrolled past the header, in both tables of contents.
  function setUpToc() {
    const links = $$('.toc-link');
    if (!links.length) return;
    const idOf = (link) => decodeURIComponent(link.hash.slice(1));
    const headings = [...new Set(links.map(idOf))].map((id) => document.getElementById(id)).filter(Boolean);
    if (!headings.length) return;
    const mobileToc = $('.mobile-toc');
    const current = $('.mobile-toc-current');
    let frame = 0;

    const update = () => {
      frame = 0;
      const line = $('.site-header').offsetHeight + (mobileToc?.offsetHeight ?? 0) + 64;
      let active = headings[0];
      for (const heading of headings) {
        if (heading.getBoundingClientRect().top <= line) active = heading;
        else break;
      }
      // The last heading can't always scroll up to the line, so the bottom of the page counts as reaching it.
      if (innerHeight + scrollY >= root.scrollHeight - 2) active = headings[headings.length - 1];
      for (const link of links) {
        if (idOf(link) === active.id) link.setAttribute('aria-current', 'true');
        else link.removeAttribute('aria-current');
      }
      if (current) current.textContent = active.textContent;
    };
    const schedule = () => {
      if (!frame) frame = requestAnimationFrame(update);
    };
    update();
    addEventListener('scroll', schedule, { passive: true });
    addEventListener('resize', schedule, { passive: true });

    mobileToc?.addEventListener('click', (event) => {
      if (event.target.closest('a')) mobileToc.open = false;
    });
  }
})();
