// Mirrors dotnet_api's exact camelCase JSON shapes (System.Text.Json default).

export interface Recipient {
    id: string;
    clientId: string;
    name: string;
    phoneNumber: string;
    email: string | null;
    address: string | null;
    ageRange: string | null;
    gender: string | null;
    district: string | null;
    isActive: boolean;
    createdAt: string;
}

export type DeliveryStatus = 'Pending' | 'Sent' | 'Partial' | 'Failed';
export type RecipientDeliveryStatus = 'Pending' | 'Sent' | 'Failed' | 'Delivered';

export interface NotificationRecipient {
    id: string;
    notificationId: string;
    name: string | null;
    phoneNumber: string;
    status: RecipientDeliveryStatus;
    errorReason: string | null;
    gatewayMessageId: string | null;
    gatewayPayload: string | null;
    createdAt: string;
    updatedAt: string | null;
    deliveredAt: string | null;
    costAmount: number | null;
    costCurrency: string | null;
}

export interface NotificationRecord {
    id: string;
    userId: string;
    title: string;
    message: string;
    type: string;
    referenceId: string | null;
    createdByUserId: string | null;
    deliveryStatus: DeliveryStatus;
    errorDetails: string | null;
    recipientsSummary: string | null;
    isRead: boolean;
    createdAt: string;
    readAt: string | null;
    recipients: NotificationRecipient[];
}

export interface SmsPackage {
    id: string;
    name: string;
    description: string | null;
    maxSmsLimit: number | null;
    pricePerSms: number;
}

export interface ClientPayment {
    id: string;
    amountPaid: number;
    smsAllocated: number;
    smsConsumed: number;
    smsRemaining: number;
    paidAt: string;
    notes: string | null;
    package: { id: string; name: string; pricePerSms: number } | null;
}

export interface ClientSummary {
    id: string;
    name: string;
    ssidn: string;
    smsCostPerMessage: number;
    createdAt: string;
    subscription: {
        currentPackage: SmsPackage | null;
        totalAllocated: number;
        totalConsumed: number;
        totalRemaining: number;
        payments: ClientPayment[];
    };
}
