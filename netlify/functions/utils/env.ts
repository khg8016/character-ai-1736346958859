import { z } from 'zod';

export const requiredEnvVars = {
  STRIPE_SECRET_KEY: process.env.STRIPE_SECRET_KEY!,
  VITE_STRIPE_PUBLIC_KEY: process.env.VITE_STRIPE_PUBLIC_KEY!,
  STRIPE_WEBHOOK_SECRET: process.env.STRIPE_WEBHOOK_SECRET!,
  SUPABASE_URL: process.env.VITE_SUPABASE_URL!,
  SUPABASE_ANON_KEY: process.env.VITE_SUPABASE_ANON_KEY!
} as const;

const envSchema = z.object({
  STRIPE_SECRET_KEY: z.string().min(1),
  VITE_STRIPE_PUBLIC_KEY: z.string().min(1),
  STRIPE_WEBHOOK_SECRET: z.string().min(1),
  SUPABASE_URL: z.string().url(),
  SUPABASE_ANON_KEY: z.string().min(1)
});

export function validateEnvVars() {
  try {
    envSchema.parse(requiredEnvVars);
  } catch (error) {
    console.error('Missing required environment variables:', error);
    throw new Error('Missing required environment variables');
  }
}