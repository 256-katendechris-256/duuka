# Windows: Enable `duuka://` deep links (Google OAuth callback)

Google OAuth on Windows desktop uses a deep link callback:

`duuka://login-callback?code=...`

For Windows to open your Flutter desktop app when the browser navigates to `duuka://...`, you must register a **custom URL protocol**.

## Dev (quick manual registration)

1. Build/run your app once so you know the exe path.
2. Replace `C:\PATH\TO\duuka.exe` below with your real path.
3. Run this in **PowerShell** (regular user is fine; it writes to `HKCU`):

```powershell
$exe = "C:\PATH\TO\duuka.exe"

reg add "HKCU\Software\Classes\duuka" /ve /d "URL:Duuka Protocol" /f
reg add "HKCU\Software\Classes\duuka" /v "URL Protocol" /d "" /f
reg add "HKCU\Software\Classes\duuka\DefaultIcon" /ve /d "$exe,1" /f
reg add "HKCU\Software\Classes\duuka\shell\open\command" /ve /d "`"$exe`" `"%1`"" /f
```

## Verify

After registering:
- In your browser, open: `duuka://login-callback?code=test`
- Windows should prompt to open the Duuka app (or open it directly).

## Notes

- Supabase Dashboard must allow the redirect URL: `duuka://login-callback`
- Google Cloud Console must allow the redirect URL: `https://<project-ref>.supabase.co/auth/v1/callback`

