import InputError from '@/Components/InputError';
import InputLabel from '@/Components/InputLabel';
import Modal from '@/Components/Modal';
import PrimaryButton from '@/Components/PrimaryButton';
import SecondaryButton from '@/Components/SecondaryButton';
import TextInput from '@/Components/TextInput';
import { ApiError, apiFetch } from '@/lib/apiFetch';
import { Recipient } from '@/types/models';
import { FormEventHandler, useEffect, useState } from 'react';

const AGE_RANGES = ['Infant', 'Child', 'Teen', 'Adult', 'Senior Adult'];
const GENDERS = ['Male', 'Female', 'Non-Binary', 'Other'];

type FormState = {
    name: string;
    phoneNumber: string;
    email: string;
    address: string;
    ageRange: string;
    gender: string;
    district: string;
};

const emptyForm: FormState = {
    name: '',
    phoneNumber: '',
    email: '',
    address: '',
    ageRange: '',
    gender: '',
    district: 'Harare',
};

export default function RecipientFormModal({
    show,
    recipient,
    onClose,
    onSaved,
}: {
    show: boolean;
    recipient?: Recipient | null;
    onClose: () => void;
    onSaved: (recipient: Recipient) => void;
}) {
    const [form, setForm] = useState<FormState>(emptyForm);
    const [errors, setErrors] = useState<Record<string, string[]>>({});
    const [processing, setProcessing] = useState(false);
    const [districtOptions, setDistrictOptions] = useState<string[]>([]);

    useEffect(() => {
        if (show) {
            setForm(
                recipient
                    ? {
                          name: recipient.name,
                          phoneNumber: recipient.phoneNumber,
                          email: recipient.email ?? '',
                          address: recipient.address ?? '',
                          ageRange: recipient.ageRange ?? '',
                          gender: recipient.gender ?? '',
                          district: recipient.district || 'Harare',
                      }
                    : emptyForm,
            );
            setErrors({});
            apiFetch<string[]>(route('recipients.districts'))
                .then(setDistrictOptions)
                .catch(() => setDistrictOptions([]));
        }
    }, [show, recipient]);

    const submit: FormEventHandler = async (e) => {
        e.preventDefault();
        setProcessing(true);
        setErrors({});

        const payload = {
            name: form.name,
            phoneNumber: form.phoneNumber,
            email: form.email || null,
            address: form.address || null,
            ageRange: form.ageRange || null,
            gender: form.gender || null,
            district: form.district || null,
        };

        try {
            const saved = recipient
                ? await apiFetch<Recipient>(route('recipients.update', recipient.id), {
                      method: 'PUT',
                      body: JSON.stringify(payload),
                  })
                : await apiFetch<Recipient>(route('recipients.store'), {
                      method: 'POST',
                      body: JSON.stringify(payload),
                  });

            onSaved(saved);
            onClose();
        } catch (err) {
            if (err instanceof ApiError && err.errors) {
                setErrors(err.errors);
            } else {
                setErrors({ name: [(err as Error).message ?? 'Something went wrong.'] });
            }
        } finally {
            setProcessing(false);
        }
    };

    return (
        <Modal show={show} onClose={onClose} maxWidth="md">
            <form onSubmit={submit} className="p-6">
                <h2 className="text-lg font-medium text-gray-900 dark:text-gray-100">
                    {recipient ? 'Edit recipient' : 'Add recipient'}
                </h2>

                <div className="mt-4 grid grid-cols-1 gap-4 sm:grid-cols-2">
                    <div className="sm:col-span-2">
                        <InputLabel htmlFor="name" value="Name" />
                        <TextInput
                            id="name"
                            className="mt-1 block w-full"
                            value={form.name}
                            onChange={(e) => setForm({ ...form, name: e.target.value })}
                            required
                        />
                        <InputError message={errors.name?.[0]} className="mt-1" />
                    </div>

                    <div>
                        <InputLabel htmlFor="phoneNumber" value="Phone" />
                        <TextInput
                            id="phoneNumber"
                            type="tel"
                            className="mt-1 block w-full"
                            value={form.phoneNumber}
                            onChange={(e) => setForm({ ...form, phoneNumber: e.target.value })}
                            required
                        />
                        <InputError message={errors.phoneNumber?.[0]} className="mt-1" />
                    </div>

                    <div>
                        <InputLabel htmlFor="email" value="Email" />
                        <TextInput
                            id="email"
                            type="email"
                            className="mt-1 block w-full"
                            value={form.email}
                            onChange={(e) => setForm({ ...form, email: e.target.value })}
                        />
                        <InputError message={errors.email?.[0]} className="mt-1" />
                    </div>

                    <div className="sm:col-span-2">
                        <InputLabel htmlFor="address" value="Address" />
                        <TextInput
                            id="address"
                            className="mt-1 block w-full"
                            value={form.address}
                            onChange={(e) => setForm({ ...form, address: e.target.value })}
                        />
                    </div>

                    <div>
                        <InputLabel htmlFor="ageRange" value="Age range" />
                        <select
                            id="ageRange"
                            className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 dark:border-gray-700 dark:bg-gray-900 dark:text-gray-300"
                            value={form.ageRange}
                            onChange={(e) => setForm({ ...form, ageRange: e.target.value })}
                        >
                            <option value="">—</option>
                            {AGE_RANGES.map((a) => (
                                <option key={a} value={a}>
                                    {a}
                                </option>
                            ))}
                        </select>
                    </div>

                    <div>
                        <InputLabel htmlFor="gender" value="Gender" />
                        <select
                            id="gender"
                            className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 dark:border-gray-700 dark:bg-gray-900 dark:text-gray-300"
                            value={form.gender}
                            onChange={(e) => setForm({ ...form, gender: e.target.value })}
                        >
                            <option value="">—</option>
                            {GENDERS.map((g) => (
                                <option key={g} value={g}>
                                    {g}
                                </option>
                            ))}
                        </select>
                        <p className="mt-1 text-xs text-gray-500 dark:text-gray-400">
                            Used to prefix "madzibaba"/"madzimai" when a message template contains {'{name}'}.
                        </p>
                    </div>

                    <div className="sm:col-span-2">
                        <InputLabel htmlFor="district" value="District" />
                        <TextInput
                            id="district"
                            list="district-options"
                            className="mt-1 block w-full"
                            value={form.district}
                            onChange={(e) => setForm({ ...form, district: e.target.value })}
                        />
                        <datalist id="district-options">
                            {districtOptions.map((d) => (
                                <option key={d} value={d} />
                            ))}
                        </datalist>
                        <InputError message={errors.district?.[0]} className="mt-1" />
                    </div>
                </div>

                <div className="mt-6 flex justify-end gap-3">
                    <SecondaryButton onClick={onClose} disabled={processing}>
                        Cancel
                    </SecondaryButton>
                    <PrimaryButton disabled={processing}>{recipient ? 'Save changes' : 'Add recipient'}</PrimaryButton>
                </div>
            </form>
        </Modal>
    );
}
