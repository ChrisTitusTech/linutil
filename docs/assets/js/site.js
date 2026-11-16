// Site chrome: menus, keyboard shortcuts, search, table of contents, and code copy buttons.
(() => {
  const root = document.documentElement;
  const $ = (selector, scope = document) => scope.querySelector(selector);
  const $$ = (selector, scope = document) => [...scope.querySelectorAll(selector)];
  const typing = (target) => target.closest?.('input, textarea, select, [contenteditable="true"]');

  // Single-key shortcuts: p and n go to the previous and next page.
  document.addEventListener('keydown', (event) => {
    if (event.ctrlKey || event.metaKey || event.altKey || typing(event.target) || $('dialog[open]')) return;
    // The homepage menu takes its own keys while it has focus.
    if (event.target.closest?.('.tui')) return;
    if (event.key === 'p' || event.key === 'n') $(`[data-key="${event.key}"]`)?.click();
  });

  // Status bar: how far down the page you are, the way a terminal editor shows it.
  const progress = $('.status-progress');
  let progressFrame = 0;
  const showProgress = () => {
    progressFrame = 0;
    const max = root.scrollHeight - innerHeight;
    if (max <= 0) progress.textContent = 'All';
    else if (scrollY <= 0) progress.textContent = 'Top';
    else if (scrollY >= max - 2) progress.textContent = 'Bot';
    else progress.textContent = `${Math.round((scrollY / max) * 100)}%`;
  };
  showProgress();
  addEventListener(
    'scroll',
    () => {
      if (!progressFrame) progressFrame = requestAnimationFrame(showProgress);
    },
    { passive: true }
  );

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

  setUpSearch();
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

  function setUpSearch() {
    const dialog = $('.search');
    const input = $('input', dialog);
    const note = $('.search-note', dialog);
    const list = $('.search-results', dialog);
    const idleNote = note.textContent;
    let index;
    let items = [];
    let active = 0;
    let latest = 0;

    // Fetched on first open. A failed fetch is forgotten so the next search tries again.
    const loadIndex = () => {
      index ??= fetch(dialog.dataset.index)
        .then((response) => {
          if (!response.ok) throw new Error(`HTTP ${response.status}`);
          return response.json();
        })
        .catch((error) => {
          index = undefined;
          throw error;
        });
      return index;
    };

    const open = () => {
      if (dialog.open) return;
      dialog.showModal();
      root.setAttribute('data-search-open', '');
      input.select();
      loadIndex().catch(() => {});
    };
    $$('[data-search-open]').forEach((button) => button.addEventListener('click', open));
    dialog.addEventListener('close', () => root.removeAttribute('data-search-open'));
    dialog.addEventListener('click', (event) => {
      if (event.target === dialog) dialog.close();
    });
    document.addEventListener('keydown', (event) => {
      if ((event.metaKey || event.ctrlKey) && event.key.toLowerCase() === 'k') {
        event.preventDefault();
        if (dialog.open) dialog.close();
        else open();
      } else if (event.key === '/' && !typing(event.target) && !dialog.open) {
        event.preventDefault();
        open();
      }
    });

    const setNote = (text, hidden = false) => {
      note.textContent = text;
      note.classList.toggle('sr-only', hidden);
    };

    const setActive = (i) => {
      active = i;
      $$('.search-result', list).forEach((link, j) => {
        link.dataset.active = String(i === j);
        link.parentElement.setAttribute('aria-selected', String(i === j));
      });
      if (items.length) {
        input.setAttribute('aria-activedescendant', `search-item-${i}`);
        list.children[i].scrollIntoView({ block: 'nearest' });
      } else {
        input.removeAttribute('aria-activedescendant');
      }
    };

    const render = (found) => {
      items = found;
      list.replaceChildren(
        ...found.map((item, i) => {
          const li = document.createElement('li');
          li.id = `search-item-${i}`;
          li.setAttribute('role', 'option');
          // Results are picked from the search box with the arrow keys, so the links stay out of the tab order.
          const link = document.createElement('a');
          link.href = item.url;
          link.tabIndex = -1;
          link.className = `search-result search-result--${item.kind}`;
          const title = document.createElement('span');
          title.className = 'search-result-title';
          title.textContent = item.title;
          const excerpt = document.createElement('span');
          excerpt.className = 'search-result-excerpt';
          excerpt.innerHTML = item.excerpt;
          link.append(title, excerpt);
          link.addEventListener('mousemove', () => active !== i && setActive(i));
          link.addEventListener('click', () => dialog.close());
          li.append(link);
          return li;
        })
      );
      list.hidden = !found.length;
      input.setAttribute('aria-expanded', String(found.length > 0));
      setActive(0);
    };

    input.addEventListener('input', () => {
      const query = input.value.trim();
      const run = ++latest;
      if (!query) {
        render([]);
        setNote(idleNote);
        return;
      }
      loadIndex().then(
        (entries) => {
          if (run !== latest) return;
          const found = search(entries, query);
          render(found);
          if (found.length) setNote(`${found.length} results`, true);
          else setNote(`No results for "${query}".`);
        },
        () => {
          if (run !== latest) return;
          render([]);
          setNote("Search couldn't load. Check your connection and try again.");
        }
      );
    });

    input.addEventListener('keydown', (event) => {
      // Enter while an input method is composing commits the text rather than opening a result.
      if (!items.length || event.isComposing) return;
      if (event.key === 'ArrowDown') {
        event.preventDefault();
        setActive((active + 1) % items.length);
      } else if (event.key === 'ArrowUp') {
        event.preventDefault();
        setActive((active - 1 + items.length) % items.length);
      } else if (event.key === 'Enter') {
        event.preventDefault();
        dialog.close();
        window.location.href = items[active].url;
      }
    });
  }

  // Index entries are page sections. Every term has to appear in the page title, section heading, or text.
  // Pages are ranked by their best section, and sections are listed under the page when they match on their own.
  function search(entries, query) {
    const terms = query.toLowerCase().split(/\s+/);
    const pages = new Map();
    for (const entry of entries) {
      const title = entry.page.toLowerCase();
      const heading = entry.heading.toLowerCase();
      const text = entry.text.toLowerCase();
      if (!terms.every((term) => title.includes(term) || heading.includes(term) || text.includes(term))) continue;
      let score = 0;
      for (const term of terms) {
        if (title.includes(term)) score += 10;
        if (heading.includes(term)) score += 6;
        if (text.includes(term)) score += 1;
      }
      const url = entry.url.split('#')[0];
      if (!pages.has(url)) pages.set(url, { title: entry.page, url, score: 0, intro: null, sections: [] });
      const page = pages.get(url);
      page.score = Math.max(page.score, score);
      if (!entry.heading) page.intro = entry;
      else if (terms.every((term) => heading.includes(term) || text.includes(term))) page.sections.push({ entry, score });
    }

    return [...pages.values()]
      .sort((a, b) => b.score - a.score)
      .slice(0, 8)
      .flatMap((page) => {
        const sections = page.sections.sort((a, b) => b.score - a.score);
        // Without a matching intro the best section stands in for the page, so it isn't listed twice.
        const lead = page.intro ?? sections.shift()?.entry;
        sections.splice(3);
        return [
          { kind: 'page', url: page.url, title: page.title, excerpt: excerpt(lead ? lead.text : '', terms) },
          ...sections.map(({ entry }) => ({
            kind: 'section',
            url: entry.url,
            title: entry.heading,
            excerpt: excerpt(entry.text, terms),
          })),
        ];
      });
  }

  // A slice of text around the first match, with every match marked.
  function excerpt(text, terms) {
    const lower = text.toLowerCase();
    const hits = terms.map((term) => lower.indexOf(term)).filter((i) => i !== -1);
    const start = hits.length ? Math.max(0, Math.min(...hits) - 40) : 0;
    let snippet = text.slice(start, start + 160);
    if (start > 0) snippet = `...${snippet}`;
    if (start + 160 < text.length) snippet += '...';
    const pattern = new RegExp(`(${terms.map((term) => term.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')).join('|')})`, 'gi');
    return snippet
      .split(pattern)
      .map((part, i) => (i % 2 ? `<mark>${escapeHtml(part)}</mark>` : escapeHtml(part)))
      .join('');
  }

  function escapeHtml(text) {
    const map = { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' };
    return text.replace(/[&<>"']/g, (char) => map[char]);
  }

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
