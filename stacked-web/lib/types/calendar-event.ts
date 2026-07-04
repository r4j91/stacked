export type CalendarEvent = {
  id: string;
  title: string;
  startDate: string;
  endDate: string;
  isAllDay: boolean;
  calendarTitle: string;
  calendarColor?: string;
  htmlLink?: string;
};

export type GoogleCalendarStatus = {
  configured: boolean;
  connected: boolean;
  email: string | null;
  importEnabled: boolean;
};

export type GoogleCalendarConnectionRow = {
  user_id: string;
  refresh_token: string;
  access_token: string | null;
  token_expires_at: string | null;
  google_account_email: string | null;
  import_enabled: boolean;
};
