export type TokenPair = {
  accessToken: string;
  refreshToken: string;
  expiresIn: number;
};

export type AuthTokenPayload = {
  sub: string;
  email: string;
};
