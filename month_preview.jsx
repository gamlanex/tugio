import { useState } from "react";

const TODAY = new Date(2026, 3, 11); // April 11, 2026

const WEEKDAYS = ["Pn", "Wt", "Śr", "Cz", "Pt", "Sb", "Nd"];

const BOOKINGS = [
  { id: "b1", service: "Dentysta",   start: new Date(2026,3,11,12,0),  durationMinutes: 60,  status: "booked" },
  { id: "b2", service: "Spotkanie",  start: new Date(2026,3,11,15,30), durationMinutes: 30,  status: "inquiry" },
  { id: "b3", service: "Psycholog",  start: new Date(2026,3,12,10,30), durationMinutes: 60,  status: "booked" },
  { id: "b4", service: "Trening",    start: new Date(2026,3,15,17,0),  durationMinutes: 60,  status: "booked" },
  { id: "b5", service: "Fryzjer",    start: new Date(2026,3,18,9,0),   durationMinutes: 60,  status: "booked" },
  { id: "b6", service: "Masaż",      start: new Date(2026,3,22,11,0),  durationMinutes: 60,  status: "inquiry" },
  { id: "b7", service: "Lekarz",     start: new Date(2026,3,25,13,0),  durationMinutes: 30,  status: "booked" },
  { id: "b8", service: "Trening",    start: new Date(2026,3,28,18,0),  durationMinutes: 60,  status: "booked" },
];

// Wolne sloty usługodawcy (Fryzjer Jan Kowalski)
const FREE_SLOTS = ["09:00", "10:00", "11:30", "13:00", "15:00", "17:00"];
const SLOT_DURATION = 60;
const START_HOUR = 7;
const END_HOUR = 21;
const TOTAL_MINUTES = (END_HOUR - START_HOUR) * 60;

function sameDay(a, b) {
  return a.getFullYear() === b.getFullYear() &&
    a.getMonth() === b.getMonth() &&
    a.getDate() === b.getDate();
}

function getBookingsForDay(day) {
  return BOOKINGS.filter(b => sameDay(b.start, day))
    .sort((a, b) => a.start - b.start);
}

function getFreeSlotsForDay(day, dayBookings) {
  return FREE_SLOTS.map(slot => {
    const [h, m] = slot.split(":").map(Number);
    if (h < START_HOUR || h >= END_HOUR) return null;
    const slotStart = new Date(day.getFullYear(), day.getMonth(), day.getDate(), h, m);
    const slotEnd = new Date(slotStart.getTime() + SLOT_DURATION * 60000);
    const occupied = dayBookings.some(b => {
      const bEnd = new Date(b.start.getTime() + b.durationMinutes * 60000);
      return b.start < slotEnd && bEnd > slotStart;
    });
    if (occupied) return null;
    const midMin = (h - START_HOUR) * 60 + m + SLOT_DURATION / 2;
    return midMin / TOTAL_MINUTES;
  }).filter(f => f !== null);
}

function SlotDots({ fractions, cellHeight }) {
  const D = 5;
  const MIN_GAP = 6;
  const totalH = cellHeight - 16;

  let positions = fractions.map(f => f * totalH).sort((a, b) => a - b);
  for (let i = 1; i < positions.length; i++) {
    if (positions[i] - positions[i - 1] < MIN_GAP) {
      positions[i] = positions[i - 1] + MIN_GAP;
    }
  }
  const overflow = positions.length ? positions[positions.length - 1] + D / 2 - totalH : 0;
  if (overflow > 0) {
    positions = positions.map(p => Math.max(D / 2, Math.min(p - overflow, totalH - D / 2)));
  }

  return (
    <div style={{ position: "absolute", top: 8, bottom: 8, right: 2, width: 7 }}>
      {positions.map((y, i) => (
        <div key={i} style={{
          position: "absolute",
          top: y - D / 2,
          right: 0,
          width: D,
          height: D,
          borderRadius: "50%",
          background: "transparent",
          border: "1.2px solid #3b82f6",
        }} />
      ))}
    </div>
  );
}

function DayCell({ day, selectedDate, onSelect, cellHeight = 80 }) {
  const isCurrentMonth = day.getMonth() === selectedDate.getMonth();
  const isSelected = sameDay(day, selectedDate);
  const isToday = sameDay(day, TODAY);

  const dayBookings = getBookingsForDay(day);
  const visibleBars = dayBookings.slice(0, 2);
  const moreBars = dayBookings.length > 2;
  const freeSlotsForDay = isCurrentMonth ? getFreeSlotsForDay(day, dayBookings) : [];
  const hasFreeSlots = freeSlotsForDay.length > 0;

  let bg = "white";
  let borderColor = "rgba(0,0,0,0.12)";
  let borderWidth = 1;

  if (isToday) {
    bg = "rgba(99,102,241,0.13)";
    borderColor = "#6366f1";
    borderWidth = 1.6;
  } else if (isSelected) {
    bg = "rgba(99,102,241,0.08)";
    borderColor = "rgba(99,102,241,0.5)";
  } else if (hasFreeSlots && isCurrentMonth) {
    bg = "rgba(59,130,246,0.04)";
  } else if (!isCurrentMonth) {
    bg = "#f9fafb";
  }

  return (
    <div
      onClick={() => onSelect(day)}
      style={{
        height: cellHeight,
        background: bg,
        border: `${borderWidth}px solid ${borderColor}`,
        borderRadius: 10,
        padding: "4px 8px 3px 4px",
        cursor: "pointer",
        position: "relative",
        overflow: "hidden",
        boxSizing: "border-box",
        transition: "background 0.15s",
      }}
    >
      {/* Kółeczka wolnych slotów */}
      {hasFreeSlots && <SlotDots fractions={freeSlotsForDay} cellHeight={cellHeight} />}

      {/* Numer dnia */}
      {isToday ? (
        <div style={{
          width: 22, height: 22,
          borderRadius: "50%",
          background: "#6366f1",
          display: "flex", alignItems: "center", justifyContent: "center",
          marginBottom: 3,
        }}>
          <span style={{ color: "white", fontWeight: 800, fontSize: 11, lineHeight: 1 }}>
            {day.getDate()}
          </span>
        </div>
      ) : (
        <div style={{
          fontWeight: isSelected ? 800 : 600,
          fontSize: 11,
          color: isCurrentMonth ? "#1f2937" : "#9ca3af",
          lineHeight: 1,
          marginBottom: 3,
        }}>
          {day.getDate()}
        </div>
      )}

      {/* Paseczki rezerwacji */}
      {visibleBars.map((b, i) => (
        <div key={b.id} style={{
          height: 5,
          width: "calc(100% - 14px)",
          marginBottom: 2,
          borderRadius: 999,
          background: b.status === "booked"
            ? "rgba(34,197,94,0.85)"
            : "rgba(251,146,60,0.85)",
        }} />
      ))}
      {moreBars && (
        <div style={{ fontSize: 9, color: "#6b7280", lineHeight: 1 }}>+{dayBookings.length - 2}</div>
      )}
    </div>
  );
}

export default function MonthCalendarView() {
  const [selectedDate, setSelectedDate] = useState(TODAY);
  const [currentMonth, setCurrentMonth] = useState(new Date(2026, 3, 1));

  const firstOfMonth = new Date(currentMonth.getFullYear(), currentMonth.getMonth(), 1);
  const startOffset = (firstOfMonth.getDay() + 6) % 7; // Monday=0
  const gridStart = new Date(firstOfMonth);
  gridStart.setDate(gridStart.getDate() - startOffset);

  const days = Array.from({ length: 42 }, (_, i) => {
    const d = new Date(gridStart);
    d.setDate(d.getDate() + i);
    return d;
  });

  const monthNames = ["Styczeń","Luty","Marzec","Kwiecień","Maj","Czerwiec",
    "Lipiec","Sierpień","Wrzesień","Październik","Listopad","Grudzień"];

  const prevMonth = () => setCurrentMonth(new Date(currentMonth.getFullYear(), currentMonth.getMonth() - 1, 1));
  const nextMonth = () => setCurrentMonth(new Date(currentMonth.getFullYear(), currentMonth.getMonth() + 1, 1));

  const selectedBookings = getBookingsForDay(selectedDate);

  return (
    <div style={{
      fontFamily: "-apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif",
      background: "#f6f7fb",
      minHeight: "100vh",
      padding: 20,
      boxSizing: "border-box",
    }}>
      {/* Nagłówek aplikacji */}
      <div style={{
        display: "flex", alignItems: "center", gap: 10,
        marginBottom: 20,
      }}>
        <div style={{
          width: 36, height: 36, borderRadius: 10,
          background: "#6366f1",
          display: "flex", alignItems: "center", justifyContent: "center",
          color: "white", fontWeight: 900, fontSize: 18,
        }}>T</div>
        <span style={{ fontWeight: 700, fontSize: 20, color: "#1e1b4b" }}>Tugio</span>
        <div style={{ marginLeft: "auto", display: "flex", gap: 8 }}>
          {["Dzień","Tydzień","Miesiąc"].map(m => (
            <button key={m} style={{
              padding: "5px 12px",
              borderRadius: 20,
              border: "none",
              background: m === "Miesiąc" ? "#6366f1" : "#e5e7eb",
              color: m === "Miesiąc" ? "white" : "#374151",
              fontWeight: 600,
              fontSize: 12,
              cursor: "pointer",
            }}>{m}</button>
          ))}
        </div>
      </div>

      {/* Panel kalendarza */}
      <div style={{
        background: "white",
        borderRadius: 20,
        padding: 16,
        boxShadow: "0 1px 8px rgba(0,0,0,0.07)",
        marginBottom: 16,
      }}>
        {/* Nawigacja miesiąca */}
        <div style={{ display: "flex", alignItems: "center", marginBottom: 12 }}>
          <button onClick={prevMonth} style={{
            background: "none", border: "none", cursor: "pointer",
            fontSize: 18, color: "#6366f1", padding: "0 8px",
          }}>‹</button>
          <div style={{ flex: 1, textAlign: "center", fontWeight: 700, fontSize: 15, color: "#1f2937" }}>
            {monthNames[currentMonth.getMonth()]} {currentMonth.getFullYear()}
          </div>
          <button onClick={nextMonth} style={{
            background: "none", border: "none", cursor: "pointer",
            fontSize: 18, color: "#6366f1", padding: "0 8px",
          }}>›</button>
          <button onClick={() => { setSelectedDate(TODAY); setCurrentMonth(new Date(2026, 3, 1)); }}
            style={{
              background: "none", border: "1px solid #6366f1",
              borderRadius: 8, padding: "3px 10px",
              color: "#6366f1", fontSize: 12, fontWeight: 600, cursor: "pointer",
            }}>Dziś</button>
        </div>

        {/* Nagłówki dni */}
        <div style={{ display: "grid", gridTemplateColumns: "repeat(7,1fr)", gap: 6, marginBottom: 6 }}>
          {WEEKDAYS.map(d => (
            <div key={d} style={{
              textAlign: "center", fontSize: 11, fontWeight: 700,
              color: "#6b7280", height: 24, display: "flex",
              alignItems: "center", justifyContent: "center",
            }}>{d}</div>
          ))}
        </div>

        {/* Siatka dni */}
        <div style={{ display: "grid", gridTemplateColumns: "repeat(7,1fr)", gap: 6 }}>
          {days.map((day, i) => (
            <DayCell
              key={i}
              day={day}
              selectedDate={selectedDate}
              onSelect={(d) => {
                setSelectedDate(d);
                setCurrentMonth(new Date(d.getFullYear(), d.getMonth(), 1));
              }}
              cellHeight={76}
            />
          ))}
        </div>
      </div>

      {/* Legenda */}
      <div style={{
        display: "flex", gap: 16, flexWrap: "wrap",
        background: "white", borderRadius: 14, padding: "10px 16px",
        boxShadow: "0 1px 4px rgba(0,0,0,0.05)", marginBottom: 16,
      }}>
        <div style={{ display: "flex", alignItems: "center", gap: 6, fontSize: 12, color: "#374151" }}>
          <div style={{ width: 24, height: 5, borderRadius: 999, background: "rgba(34,197,94,0.85)" }} />
          Potwierdzona rezerwacja
        </div>
        <div style={{ display: "flex", alignItems: "center", gap: 6, fontSize: 12, color: "#374151" }}>
          <div style={{ width: 24, height: 5, borderRadius: 999, background: "rgba(251,146,60,0.85)" }} />
          Zapytanie (inquiry)
        </div>
        <div style={{ display: "flex", alignItems: "center", gap: 6, fontSize: 12, color: "#374151" }}>
          <div style={{ width: 8, height: 8, borderRadius: "50%", border: "1.2px solid #3b82f6" }} />
          Wolny slot usługodawcy
        </div>
        <div style={{ display: "flex", alignItems: "center", gap: 6, fontSize: 12, color: "#374151" }}>
          <div style={{ width: 22, height: 22, borderRadius: "50%", background: "#6366f1", display: "flex", alignItems: "center", justifyContent: "center" }}>
            <span style={{ color: "white", fontSize: 10, fontWeight: 800 }}>D</span>
          </div>
          Dzisiaj
        </div>
      </div>

      {/* Szczegóły wybranego dnia */}
      <div style={{
        background: "white", borderRadius: 16, padding: 16,
        boxShadow: "0 1px 8px rgba(0,0,0,0.07)",
      }}>
        <div style={{ fontWeight: 700, fontSize: 13, color: "#374151", marginBottom: 10 }}>
          {selectedDate.getDate()}.{String(selectedDate.getMonth()+1).padStart(2,"0")}.{selectedDate.getFullYear()}
          {sameDay(selectedDate, TODAY) && <span style={{ marginLeft: 8, color: "#6366f1", fontSize: 11 }}>• Dzisiaj</span>}
        </div>
        {selectedBookings.length === 0 ? (
          <div style={{ fontSize: 12, color: "#9ca3af" }}>Brak rezerwacji na ten dzień</div>
        ) : (
          selectedBookings.map(b => {
            const end = new Date(b.start.getTime() + b.durationMinutes * 60000);
            const color = b.status === "booked" ? "#16a34a" : "#ea580c";
            const bg = b.status === "booked" ? "rgba(34,197,94,0.1)" : "rgba(251,146,60,0.1)";
            return (
              <div key={b.id} style={{
                display: "flex", alignItems: "center", gap: 10,
                background: bg, border: `1px solid ${color}`,
                borderRadius: 10, padding: "8px 12px", marginBottom: 6,
              }}>
                <div style={{ width: 4, height: 32, borderRadius: 2, background: color }} />
                <div>
                  <div style={{ fontWeight: 700, fontSize: 13, color: "#1f2937" }}>{b.service}</div>
                  <div style={{ fontSize: 11, color: "#6b7280" }}>
                    {String(b.start.getHours()).padStart(2,"0")}:{String(b.start.getMinutes()).padStart(2,"0")} –{" "}
                    {String(end.getHours()).padStart(2,"0")}:{String(end.getMinutes()).padStart(2,"0")}
                  </div>
                </div>
                <div style={{
                  marginLeft: "auto", fontSize: 10, fontWeight: 700,
                  color, background: "white", border: `1px solid ${color}`,
                  borderRadius: 6, padding: "2px 7px",
                }}>
                  {b.status === "booked" ? "Booked" : "Inquiry"}
                </div>
              </div>
            );
          })
        )}
      </div>
    </div>
  );
}
