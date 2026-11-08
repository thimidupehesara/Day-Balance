import crypto from 'crypto';
import argon2 from 'argon2';
import jwt from 'jsonwebtoken';
import { eq, and, isNull, gt, like } from 'drizzle-orm';
import { db } from '../../db/connection';
import { users, refreshTokens, categories } from '../../db/schema';
import { customCategoryPrefix } from '../categories/category-access';
import { env } from '../../config/env';

interface TokenPair {
  accessToken: string;
  refreshToken: string;
}

interface UserProfile {
  id: string;
  email: string;
  displayName: string | null;
  wakeTime: string | null;
  bedtime: string | null;
  routineMinutes: number | null;
  onboardingDone: boolean | null;
  createdAt: Date | null;
}

export class AuthService {
  private static hashToken(token: string): string {
    return crypto.createHash('sha256').update(token).digest('hex');
  }

  private static generateTokens(userId: string): TokenPair {
    const accessToken = jwt.sign({ userId }, env.JWT_ACCESS_SECRET, {
      expiresIn: '15m',
    });

    const refreshToken = jwt.sign(
      { userId, jti: crypto.randomUUID() },
      env.JWT_REFRESH_SECRET,
      { expiresIn: '30d' },
    );

    return { accessToken, refreshToken };
  }

  private static async storeRefreshToken(
    userId: string,
    refreshToken: string,
  ): Promise<void> {
    const tokenHash = this.hashToken(refreshToken);
    const expiresAt = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000); // 30 days

    await db.insert(refreshTokens).values({
      userId,
      tokenHash,
      expiresAt,
    });
  }

  static async register(
    email: string,
    password: string,
    displayName?: string,
  ): Promise<{ user: UserProfile; tokens: TokenPair }> {
    const existing = await db
      .select({ id: users.id })
      .from(users)
      .where(eq(users.email, email))
      .limit(1);

    if (existing.length > 0) {
      const err = new Error('Email is already registered');
      (err as any).statusCode = 409;
      throw err;
    }

    const passwordHash = await argon2.hash(password);

    const [newUser] = await db
      .insert(users)
      .values({
        email,
        passwordHash,
        displayName: displayName?.trim() || 'Hello!',
        routineMinutes: 0,
        onboardingDone: false,
      })
      .returning({
        id: users.id,
        email: users.email,
        displayName: users.displayName,
        wakeTime: users.wakeTime,
        bedtime: users.bedtime,
        routineMinutes: users.routineMinutes,
        onboardingDone: users.onboardingDone,
        createdAt: users.createdAt,
      });

    newUser.displayName = newUser.displayName || 'Hello!';

    const tokens = this.generateTokens(newUser.id);
    await this.storeRefreshToken(newUser.id, tokens.refreshToken);

    return { user: newUser, tokens };
  }

  static async login(
    email: string,
    password: string,
  ): Promise<{ user: UserProfile; tokens: TokenPair }> {
    const [user] = await db
      .select()
      .from(users)
      .where(eq(users.email, email))
      .limit(1);

    if (!user) {
      const err = new Error('Invalid email or password');
      (err as any).statusCode = 401;
      throw err;
    }

    const isMatch = await argon2.verify(user.passwordHash, password);
    if (!isMatch) {
      const err = new Error('Invalid email or password');
      (err as any).statusCode = 401;
      throw err;
    }

    const tokens = this.generateTokens(user.id);
    await this.storeRefreshToken(user.id, tokens.refreshToken);

    const userProfile: UserProfile = {
      id: user.id,
      email: user.email,
      displayName: user.displayName || 'Hello!',
      wakeTime: user.wakeTime,
      bedtime: user.bedtime,
      routineMinutes: user.routineMinutes,
      onboardingDone: user.onboardingDone,
      createdAt: user.createdAt,
    };

    return { user: userProfile, tokens };
  }

  static async refresh(refreshToken: string): Promise<TokenPair> {
    let payload: { userId: string };
    try {
      payload = jwt.verify(refreshToken, env.JWT_REFRESH_SECRET) as {
        userId: string;
      };
    } catch {
      const err = new Error('Invalid or expired refresh token');
      (err as any).statusCode = 401;
      throw err;
    }

    const tokenHash = this.hashToken(refreshToken);

    const [stored] = await db
      .select()
      .from(refreshTokens)
      .where(
        and(
          eq(refreshTokens.tokenHash, tokenHash),
          isNull(refreshTokens.revokedAt),
          gt(refreshTokens.expiresAt, new Date()),
        ),
      )
      .limit(1);

    if (!stored) {
      const err = new Error('Refresh token is invalid or has been revoked');
      (err as any).statusCode = 401;
      throw err;
    }

    // Revoke old refresh token (rotation)
    await db
      .update(refreshTokens)
      .set({ revokedAt: new Date() })
      .where(eq(refreshTokens.id, stored.id));

    // Generate new token pair
    const tokens = this.generateTokens(payload.userId);
    await this.storeRefreshToken(payload.userId, tokens.refreshToken);

    return tokens;
  }

  static async logout(refreshToken: string): Promise<void> {
    const tokenHash = this.hashToken(refreshToken);
    await db
      .update(refreshTokens)
      .set({ revokedAt: new Date() })
      .where(eq(refreshTokens.tokenHash, tokenHash));
  }

  static async deleteAccount(userId: string): Promise<void> {
    await db.transaction(async tx => {
      await tx.delete(users).where(eq(users.id, userId));
      await tx.delete(categories).where(like(categories.id, `${customCategoryPrefix(userId)}%`));
    });
  }
}
