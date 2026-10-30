// Erzeugt aus vereine-web/design mit `npm run design`. Nicht von Hand ändern.
namespace Vereine.App.Components.Design;

/// <summary>Erlaubte Icons (Phosphor, Skill vereine-design, icons.md).</summary>
public enum IconName
{
    /// <summary>Start, Übersicht</summary>
    House,
    /// <summary>Mitglieder, Mannschaft</summary>
    UsersThree,
    /// <summary>Profil, eigenes Konto</summary>
    UserCircle,
    /// <summary>Mitglied aufnehmen</summary>
    UserPlus,
    /// <summary>Termine, Kalender</summary>
    CalendarBlank,
    /// <summary>Zusage, Anwesenheit</summary>
    CalendarCheck,
    /// <summary>Spiel, Training</summary>
    SoccerBall,
    /// <summary>Aufgaben, Listen</summary>
    ClipboardText,
    /// <summary>Nachricht, E-Mail</summary>
    EnvelopeSimple,
    /// <summary>Anrufen</summary>
    Phone,
    /// <summary>Beiträge, Geld</summary>
    CurrencyEur,
    /// <summary>Benachrichtigungen</summary>
    Bell,
    /// <summary>Suchen</summary>
    MagnifyingGlass,
    /// <summary>Neu anlegen</summary>
    Plus,
    /// <summary>Bearbeiten</summary>
    PencilSimple,
    /// <summary>Löschen</summary>
    Trash,
    /// <summary>Fertig, bestätigt</summary>
    Check,
    /// <summary>Schließen, abbrechen</summary>
    X,
    /// <summary>Zurück</summary>
    CaretLeft,
    /// <summary>Öffnen, weiter (am Zeilenende)</summary>
    CaretRight,
    /// <summary>Mehr Aktionen</summary>
    DotsThree,
    /// <summary>Einstellungen</summary>
    GearSix,
    /// <summary>Neu laden, nochmal versuchen</summary>
    ArrowClockwise,
    /// <summary>Hinweis</summary>
    Info,
    /// <summary>Warnung, Fehler</summary>
    WarningCircle,
    /// <summary>Abmelden</summary>
    SignOut,
}

public static class IconNameExtensions
{
    extension(IconName name)
    {
        /// <summary>Id im Sprite wwwroot/icons.svg; die gefüllte Form hat zusätzlich "-fill".</summary>
        public string SpriteId => name switch
        {
            IconName.House => "house",
            IconName.UsersThree => "users-three",
            IconName.UserCircle => "user-circle",
            IconName.UserPlus => "user-plus",
            IconName.CalendarBlank => "calendar-blank",
            IconName.CalendarCheck => "calendar-check",
            IconName.SoccerBall => "soccer-ball",
            IconName.ClipboardText => "clipboard-text",
            IconName.EnvelopeSimple => "envelope-simple",
            IconName.Phone => "phone",
            IconName.CurrencyEur => "currency-eur",
            IconName.Bell => "bell",
            IconName.MagnifyingGlass => "magnifying-glass",
            IconName.Plus => "plus",
            IconName.PencilSimple => "pencil-simple",
            IconName.Trash => "trash",
            IconName.Check => "check",
            IconName.X => "x",
            IconName.CaretLeft => "caret-left",
            IconName.CaretRight => "caret-right",
            IconName.DotsThree => "dots-three",
            IconName.GearSix => "gear-six",
            IconName.ArrowClockwise => "arrow-clockwise",
            IconName.Info => "info",
            IconName.WarningCircle => "warning-circle",
            IconName.SignOut => "sign-out",
            _ => throw new ArgumentOutOfRangeException(nameof(name), name, null),
        };
    }
}
