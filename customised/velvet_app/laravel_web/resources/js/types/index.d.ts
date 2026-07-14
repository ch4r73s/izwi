export type UserRole = 'Admin' | 'User' | 'Guest';

export interface AuthUser {
    id: string;
    username: string;
    email: string;
    displayName: string;
    role: UserRole;
}

export type PageProps<
    T extends Record<string, unknown> = Record<string, unknown>,
> = T & {
    auth: {
        user: AuthUser | null;
    };
    flash: {
        success?: string | null;
        error?: string | null;
    };
};
