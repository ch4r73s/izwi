// TS port of TemplateResolver.php / template_resolver.dart, for LIVE PREVIEW
// ONLY — the server remains authoritative for what actually gets sent and
// billed (app/Services/Sms/TemplateResolver.php).

export function resolveTemplate(template: string, name: string, gender?: string | null): string {
    return template.replace(/\{name\}|\[name\]/gi, resolvedName(name, gender));
}

function resolvedName(name: string, gender?: string | null): string {
    const g = (gender ?? '').trim().toLowerCase();
    if (g.startsWith('m')) return `madzibaba ${name}`;
    if (g.startsWith('f')) return `madzimai ${name}`;
    return name;
}

export function smsUnits(resolvedMessage: string): number {
    return Math.ceil(resolvedMessage.length / 160) || 0;
}
