const catalogPromise = fetch('app/assets/cargo_catalog.json').then((response) => {
  if (!response.ok) throw new Error('화물 분류를 불러오지 못했습니다.');
  return response.json();
});

const escapeHtml = (text) => String(text).replace(/[&<>"']/g, (char) => ({
  '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;',
}[char]));

class CargoSelector {
  constructor(element, catalog) {
    this.element = element;
    this.categories = catalog.categories;
    this.form = element.closest('[data-request-form]');
    this.state = { category: '', supplier: '', location: '', group: '', product: '', details: '' };
    element.addEventListener('click', (event) => this.onClick(event));
    element.addEventListener('change', (event) => this.onChange(event));
    element.addEventListener('input', (event) => {
      const field = event.target.dataset.cargoField;
      if (field === 'location' || field === 'details') {
        this.state[field] = event.target.value;
        this.publish();
      }
    });
    this.render();
    this.form?.querySelector('[data-transport-destination]')?.addEventListener('input', () => this.publish());
  }

  get category() { return this.categories.find((item) => item.id === this.state.category); }
  get supplier() { return this.category?.suppliers.find((item) => item.id === this.state.supplier); }
  get group() { return this.supplier?.groups.find((item) => item.id === this.state.group); }
  get product() { return this.group?.products.find((item) => item.name === this.state.product); }

  onClick(event) {
    const button = event.target.closest('button[data-cargo-choice]');
    if (!button) return;
    const field = button.dataset.cargoChoice;
    if (field === 'category') {
      this.state = { category: button.dataset.value, supplier: '', location: '', group: '', product: '', details: '' };
      if (this.form) this.form.querySelector('[data-transport-destination]').value = '';
    } else {
      const previousRole = this.supplier?.role;
      Object.assign(this.state, { supplier: button.dataset.value, location: '', group: '', product: '', details: '' });
      if (this.form && previousRole !== this.supplier.role) this.form.querySelector('[data-transport-destination]').value = '';
      if (this.supplier.locations.length === 1) this.state.location = this.supplier.locations[0];
      if (this.supplier.groups.length === 1) this.state.group = this.supplier.groups[0].id;
      if (this.group?.products.length === 1) this.state.product = this.group.products[0].name;
    }
    this.render();
  }

  onChange(event) {
    const field = event.target.dataset.cargoField;
    if (!field) return;
    this.state[field] = event.target.value;
    if (field === 'group') {
      this.state.product = this.group?.products.length === 1 ? this.group.products[0].name : '';
      this.state.details = '';
    }
    if (field === 'product') this.state.details = '';
    if (field !== 'location' && field !== 'details') this.render();
    else this.publish();
  }

  options(items, selected, labelKey = 'name', valueKey = labelKey) {
    return '<option value="">선택해 주세요</option>' + items.map((item) =>
      `<option value="${escapeHtml(item[valueKey])}" ${item[valueKey] === selected ? 'selected' : ''}>${escapeHtml(item[labelKey])}</option>`).join('');
  }

  buttons(items, field) {
    return `<div class="cargo-options" aria-label="${field === 'category' ? '화물 종류' : '관련 업체'}">` + items.map((item) =>
      `<button type="button" data-cargo-choice="${field}" data-value="${item.id}" aria-pressed="${this.state[field] === item.id}">${escapeHtml(item.name)}</button>`).join('') + '</div>';
  }

  render() {
    const supplier = this.supplier;
    let html = '<h2>운송할 화물 종류</h2><p>화물 종류와 관련 업체를 고른 뒤 세부 품목을 선택해 주세요.</p>';
    html += this.buttons(this.categories, 'category');
    if (this.category) {
      html += `<p>${escapeHtml(this.category.description)}</p><h2>관련 업체·품목</h2>`;
      html += this.buttons(this.category.suppliers, 'supplier');
    }
    if (supplier) {
      html += `<p>${escapeHtml(supplier.description)}</p>`;
      html += supplier.locations.length
        ? `<label>출하 공장<select data-cargo-field="location">${this.options(supplier.locations.map((name) => ({ name })), this.state.location)}</select></label>`
        : `<label>출하자·상차지<input data-cargo-field="location" value="${escapeHtml(this.state.location)}" placeholder="출하자와 상차 주소를 입력해 주세요" maxlength="200"></label>`;
      html += `<label>세부 분류<select data-cargo-field="group">${this.options(supplier.groups, this.state.group, 'name', 'id')}</select></label>`;
      if (this.group) {
        html += `<label>운송 품목<select data-cargo-field="product">${this.options(this.group.products, this.state.product)}</select></label>`;
        if (this.group.note) html += `<p>${escapeHtml(this.group.note)}</p>`;
      }
      if (this.product?.note) html += `<p>${escapeHtml(this.product.note)}</p>`;
      if (this.product?.requiresDetails) html += `<label>실제 원료 품목<input data-cargo-field="details" value="${escapeHtml(this.state.details)}" placeholder="납품할 원료명을 입력해 주세요" maxlength="120"></label>`;
    }
    html += '<p class="cargo-summary" aria-live="polite"></p>';
    this.element.classList.add('cargo-selector');
    this.element.innerHTML = html;
    this.publish();
  }

  publish() {
    const isComplete = Boolean(this.product && this.state.location.trim()
      && (!this.product.requiresDetails || this.state.details.trim()));
    const destination = this.form?.querySelector('[data-transport-destination]')?.value.trim() ?? '';
    const selection = {
      ...this.state, isComplete,
      categoryName: this.category?.name ?? '', supplierName: this.supplier?.name ?? '',
      groupName: this.group?.name ?? '',
      cargoLabel: this.product?.requiresDetails ? this.state.details.trim() : this.product?.name ?? '',
      origin: this.supplier?.role === 'recipient' ? this.state.location.trim() : this.supplier?.locations.length
        ? `${this.supplier.name} · ${this.state.location}` : `${this.supplier?.name ?? ''} · ${this.state.location.trim()}`,
      destination: destination && this.supplier?.role === 'recipient' ? `${this.supplier.name} · ${destination}` : destination,
    };
    this.element.querySelector('.cargo-summary').textContent = isComplete
      ? `${selection.categoryName} / ${selection.cargoLabel} · ${selection.origin}`
      : '화물 종류, 출하 거점, 세부 분류와 품목을 선택해 주세요.';
    const origin = this.form?.querySelector('[data-transport-origin]');
    if (origin) origin.textContent = isComplete ? selection.origin : '출하 거점을 먼저 선택해 주세요.';
    const submit = this.form?.querySelector('[data-submit-transport]');
    if (submit) submit.disabled = !isComplete || !selection.destination;
    const destinationInput = this.form?.querySelector('[data-transport-destination]');
    if (destinationInput) destinationInput.placeholder = this.supplier?.role === 'recipient'
      ? 'SPC 납품 공장·거점명을 입력해 주세요' : '도착할 주소나 거점명을 입력해 주세요';
    this.element.dispatchEvent(new CustomEvent('cargo-selection-change', { bubbles: true, detail: selection }));
  }
}

document.querySelectorAll('[data-transport-categories]').forEach(async (element) => {
  try {
    new CargoSelector(element, await catalogPromise);
  } catch {
    element.innerHTML = '<p role="alert">화물 분류를 불러오지 못했습니다. 새로고침해 주세요.</p>';
  }
});
