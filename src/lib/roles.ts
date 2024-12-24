export const ROLES = {
  NURSE: 'nurse',
  PHYSICIAN: 'physician',
  CLINICIAN: 'clinician',
  ADMIN: 'admin',
  SUPERADMIN: 'superadmin',
} as const;

export type Role = typeof ROLES[keyof typeof ROLES];

export const ROLE_PERMISSIONS = {
  [ROLES.NURSE]: {
    canViewReports: true,
    canCreateReports: true,
    canManageUsers: false,
    canManageFacilities: false,
  },
  [ROLES.PHYSICIAN]: {
    canViewReports: true,
    canCreateReports: true,
    canManageUsers: false,
    canManageFacilities: false,
  },
  [ROLES.CLINICIAN]: {
    canViewReports: true,
    canCreateReports: false,
    canManageUsers: false,
    canManageFacilities: false,
  },
  [ROLES.ADMIN]: {
    canViewReports: true,
    canCreateReports: true,
    canManageUsers: true,
    canManageFacilities: true,
  },
  [ROLES.SUPERADMIN]: {
    canViewReports: true,
    canCreateReports: true,
    canManageUsers: true,
    canManageFacilities: true,
    canManageOrganizations: true,
  },
} as const;

export type Permission = keyof typeof ROLE_PERMISSIONS[Role];

export function hasPermission(role: Role, permission: Permission): boolean {
  return ROLE_PERMISSIONS[role]?.[permission] ?? false;
}