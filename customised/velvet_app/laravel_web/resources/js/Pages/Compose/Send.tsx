import InputError from '@/Components/InputError';
import InputLabel from '@/Components/InputLabel';
import PrimaryButton from '@/Components/PrimaryButton';
import TextInput from '@/Components/TextInput';
import RecipientPicker from '@/Components/recipients/RecipientPicker';
import SmsCounter from '@/Components/sms/SmsCounter';
import TemplatePreview from '@/Components/sms/TemplatePreview';
import AppLayout from '@/Layouts/AppLayout';
import { Recipient } from '@/types/models';
import { Head, useForm } from '@inertiajs/react';
import { FormEventHandler, useState } from 'react';

export default function ComposeSend() {
    const [selected, setSelected] = useState<Recipient[]>([]);
    const [pickerOpen, setPickerOpen] = useState(false);

    const { data, setData, post, processing, errors } = useForm<{
        title: string;
        message: string;
        recipients: { name: string; phoneNumber: string; gender: string | null }[];
    }>({
        title: '',
        message: '',
        recipients: [],
    });

    const applySelection = (recipients: Recipient[]) => {
        setSelected(recipients);
        setData(
            'recipients',
            recipients.map((r) => ({ name: r.name, phoneNumber: r.phoneNumber, gender: r.gender })),
        );
        setPickerOpen(false);
    };

    const removeSelected = (id: string) => {
        const next = selected.filter((r) => r.id !== id);
        applySelection(next);
    };

    const submit: FormEventHandler = (e) => {
        e.preventDefault();
        post(route('sms.store'));
    };

    return (
        <AppLayout header={<h2 className="text-xl font-semibold text-gray-800 dark:text-gray-200">Compose & Send</h2>}>
            <Head title="Compose & Send" />

            <div className="py-8">
                <div className="mx-auto max-w-2xl px-4 sm:px-6 lg:px-8">
                    <form onSubmit={submit} className="space-y-6 rounded-lg bg-white p-6 shadow dark:bg-gray-800">
                        <div>
                            <InputLabel htmlFor="title" value="Title" />
                            <TextInput
                                id="title"
                                className="mt-1 block w-full"
                                value={data.title}
                                onChange={(e) => setData('title', e.target.value)}
                            />
                            <InputError message={errors.title} className="mt-1" />
                        </div>

                        <div>
                            <div className="flex items-center justify-between">
                                <InputLabel value="Recipients" />
                                <button
                                    type="button"
                                    onClick={() => setPickerOpen(true)}
                                    className="text-sm font-medium text-indigo-600 hover:underline dark:text-indigo-400"
                                >
                                    {selected.length > 0 ? 'Change selection' : 'Select recipients'}
                                </button>
                            </div>

                            {selected.length === 0 ? (
                                <p className="mt-2 text-sm text-gray-500 dark:text-gray-400">No recipients selected.</p>
                            ) : (
                                <ul className="mt-2 flex flex-wrap gap-2">
                                    {selected.map((r) => (
                                        <li
                                            key={r.id}
                                            className="inline-flex items-center gap-1 rounded-full bg-indigo-50 px-3 py-1 text-xs font-medium text-indigo-700 dark:bg-indigo-950 dark:text-indigo-300"
                                        >
                                            {r.name}
                                            <button
                                                type="button"
                                                onClick={() => removeSelected(r.id)}
                                                className="ml-1 text-indigo-400 hover:text-indigo-600"
                                                aria-label={`Remove ${r.name}`}
                                            >
                                                ×
                                            </button>
                                        </li>
                                    ))}
                                </ul>
                            )}
                            <InputError message={errors.recipients} className="mt-1" />
                        </div>

                        <div>
                            <InputLabel htmlFor="message" value="Message" />
                            <textarea
                                id="message"
                                rows={5}
                                className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 dark:border-gray-700 dark:bg-gray-900 dark:text-gray-300"
                                value={data.message}
                                onChange={(e) => setData('message', e.target.value)}
                            />
                            <p className="mt-1 text-xs text-gray-500 dark:text-gray-400">
                                Use {'{name}'} or {'[name]'} to insert each recipient's name (with a "madzibaba"/"madzimai"
                                prefix based on their gender, when known).
                            </p>
                            <SmsCounter message={data.message} recipients={selected} />
                            <TemplatePreview message={data.message} recipients={selected} />
                            <InputError message={errors.message} className="mt-1" />
                        </div>

                        <div className="flex justify-end">
                            <PrimaryButton disabled={processing || selected.length === 0}>
                                {processing ? 'Sending…' : 'Send'}
                            </PrimaryButton>
                        </div>
                    </form>
                </div>
            </div>

            <RecipientPicker
                show={pickerOpen}
                initiallySelected={selected}
                onClose={() => setPickerOpen(false)}
                onConfirm={applySelection}
            />
        </AppLayout>
    );
}
