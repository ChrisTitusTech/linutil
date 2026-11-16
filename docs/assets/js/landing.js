// Homepage menu preview: browse the catalog with the TUI's keys. It shows entries and never runs anything.
(() => {
  const tui = document.querySelector('.tui');
  if (!tui) return;
  const $ = (selector, scope = tui) => scope.querySelector(selector);
  const $$ = (selector, scope = tui) => [...scope.querySelectorAll(selector)];

  const tabs = JSON.parse($('.tui-data').textContent);
  const tabButtons = $$('.tui-tab');
  const rows = $('.tui-rows');
  const footer = $('.tui-footer');
  const details = $('.tui-details');
  const flagNames = Object.fromEntries($$('.tui-legend--flags div').map((row) => [$('dt', row).textContent, $('dd', row).textContent]));
  const up = { name: '..', up: true };

  let tab = 0;
  let selected = 0;
  // Folders opened so far, with the row that was selected in each parent, so going back restores it.
  let path = [];

  const folder = () => path.at(-1)?.node;
  // Inside a folder the first row leads back up, as in the TUI.
  const items = () => (folder() ? [up, ...folder().entries] : tabs[tab].entries);

  const describeFlags = (flags) =>
    flags
      .split(/\s+/)
      .map((flag) => flagNames[flag] ?? (flag.startsWith('P') && flagNames[flag.slice(1)] ? `${flagNames[flag.slice(1)]} (privileged)` : ''))
      .filter(Boolean)
      .join(', ');

  const line = (className, text) => {
    const p = document.createElement('p');
    p.className = className;
    p.textContent = text;
    return p;
  };

  function showDetails(node) {
    const parts = [$('.panel-title', details)];
    if (node.up) {
      parts.push(line('tui-details-name', 'Parent directory'), line('tui-details-text', 'Return to the previous directory.'));
    } else if (node.entries) {
      parts.push(
        line('tui-details-name', node.name),
        line('tui-details-text', node.description || 'Open this category to browse its commands.'),
        line('tui-details-flags', `${node.entries.length} entries`)
      );
    } else {
      parts.push(line('tui-details-name', node.name), line('tui-details-text', node.description || 'No description available.'));
      if (node.flags) {
        const flags = line('tui-details-flags', '');
        const keys = document.createElement('b');
        keys.textContent = node.flags;
        const meaning = describeFlags(node.flags);
        flags.append(keys, meaning ? ` ${meaning}` : '');
        parts.push(flags);
      }
      if (tabs[tab].link) {
        const link = document.createElement('a');
        link.href = tabs[tab].link;
        link.textContent = 'See it in the walkthrough ->';
        parts.push(link);
      }
    }
    details.replaceChildren(...parts);
  }

  // Scrolls the list itself, never the page, so browsing doesn't move the window.
  function keepInView(row) {
    if (row.offsetTop < rows.scrollTop) rows.scrollTop = row.offsetTop;
    else if (row.offsetTop + row.offsetHeight > rows.scrollTop + rows.clientHeight) {
      rows.scrollTop = row.offsetTop + row.offsetHeight - rows.clientHeight;
    }
  }

  function select(index) {
    const list = items();
    selected = Math.min(Math.max(index, 0), list.length - 1);
    [...rows.children].forEach((row, i) => row.setAttribute('aria-selected', String(i === selected)));
    rows.setAttribute('aria-activedescendant', `tui-row-${selected}`);
    keepInView(rows.children[selected]);
    showDetails(list[selected]);
  }

  function render() {
    tabButtons.forEach((button, i) => button.setAttribute('aria-selected', String(i === tab)));
    rows.replaceChildren(
      ...items().map((node, i) => {
        const row = document.createElement('li');
        const dir = Boolean(node.up || node.entries);
        row.id = `tui-row-${i}`;
        row.className = dir ? 'tui-row is-dir' : 'tui-row';
        row.setAttribute('role', 'option');
        const name = document.createElement('span');
        name.className = 'tui-name';
        name.textContent = `${dir ? '[D]' : '[*]'} ${node.name}`;
        const flags = document.createElement('span');
        flags.className = 'tui-flag';
        flags.textContent = node.flags ?? '';
        row.append(name, flags);
        row.addEventListener('click', () => (i === selected ? open() : select(i)));
        return row;
      })
    );
    const entries = folder() ? folder().entries : tabs[tab].entries;
    footer.textContent = `${entries.length} entries · ${folder()?.name ?? tabs[tab].name}`;
    rows.scrollTop = 0;
    select(selected);
  }

  function open() {
    const node = items()[selected];
    if (node.up) back();
    else if (node.entries) {
      path.push({ node, selected });
      selected = 0;
      render();
    }
  }

  function back() {
    if (!path.length) return;
    selected = path.pop().selected;
    render();
  }

  function setTab(index) {
    if (index < 0 || index >= tabs.length) return;
    tab = index;
    path = [];
    selected = 0;
    render();
  }

  tabButtons.forEach((button, i) =>
    button.addEventListener('click', () => {
      setTab(i);
      rows.focus({ preventScroll: true });
    })
  );

  const keys = {
    ArrowDown: () => select(selected + 1),
    j: () => select(selected + 1),
    ArrowUp: () => select(selected - 1),
    k: () => select(selected - 1),
    Home: () => select(0),
    End: () => select(items().length - 1),
    Enter: open,
    ArrowRight: open,
    l: open,
    ArrowLeft: back,
    h: back,
    Escape: back,
    Backspace: back,
  };
  tui.addEventListener('keydown', (event) => {
    if (event.ctrlKey || event.metaKey || event.altKey) return;
    const action = keys[event.key] ?? (/^[1-9]$/.test(event.key) ? () => setTab(Number(event.key) - 1) : null);
    if (!action) return;
    event.preventDefault();
    action();
  });

  render();
})();
