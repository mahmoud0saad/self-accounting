export interface JwtPayload {
  sub: string;
  email: string;
  emailConfirmedAt: string | null;
}

export interface RequestUser extends JwtPayload {}
