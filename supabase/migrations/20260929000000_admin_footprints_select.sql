-- Migration: Allow admins to read all user footprints
-- Created At: 2026-09-29 KST
-- Background: user_footprints RLS only permits users to read their own rows,
-- so the admin console (anon key + admin session) receives empty results.
-- This policy grants SELECT to users whose profiles.role = 'admin'.

CREATE POLICY "Admins can select all footprints" ON public.user_footprints
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE profiles.id = auth.uid()
              AND profiles.role = 'admin'
        )
    );
