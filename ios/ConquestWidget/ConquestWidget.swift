import WidgetKit
import SwiftUI

private let appGroup = "group.com.watercherry.conquestofkorea"

struct ConquestEntry: TimelineEntry {
    let date: Date
    let territory: Int
    let dailyMoved: Int
    let steps: Int
}

struct ConquestProvider: TimelineProvider {
    func placeholder(in context: Context) -> ConquestEntry {
        ConquestEntry(date: Date(), territory: 0, dailyMoved: 0, steps: 0)
    }

    func getSnapshot(in context: Context, completion: @escaping (ConquestEntry) -> Void) {
        completion(loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ConquestEntry>) -> Void) {
        completion(Timeline(entries: [loadEntry()], policy: .never))
    }

    private func loadEntry() -> ConquestEntry {
        let defaults = UserDefaults(suiteName: appGroup)
        return ConquestEntry(
            date: Date(),
            territory: defaults?.integer(forKey: "territory") ?? 0,
            dailyMoved: defaults?.integer(forKey: "dailyMoved") ?? 0,
            steps: defaults?.integer(forKey: "steps") ?? 0
        )
    }
}

private func widgetText(_ key: String) -> String {
    NSLocalizedString(key, tableName: nil, bundle: .main, value: key, comment: "")
}

private enum WidgetPalette {
    static let mint = Color(red: 0, green: 1, blue: 0.8)
    static let accent = Color(red: 0.56, green: 0.71, blue: 1)
    static let muted = Color(red: 0.58, green: 0.64, blue: 0.78)
    static let divider = Color(red: 0.13, green: 0.19, blue: 0.36)
}

private struct WidgetGradientBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.094, green: 0.145, blue: 0.31),
                Color(red: 0.063, green: 0.102, blue: 0.22),
                Color(red: 0.031, green: 0.051, blue: 0.12)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

struct ConquestWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family

    var entry: ConquestEntry

    var body: some View {
        if #available(iOS 16.0, *), family == .accessoryCircular {
            VStack(spacing: 1) {
                Text("\(entry.territory)")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                    .widgetAccentable()
                Text(widgetText("territory"))
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
        } else if #available(iOS 16.0, *), family == .accessoryRectangular {
            VStack(alignment: .leading, spacing: 1) {
                compactRow(widgetText("territory"), entry.territory, accent: true)
                compactRow(widgetText("daily_moved_short"), entry.dailyMoved, accent: false)
                compactRow(widgetText("steps"), entry.steps, accent: false)
            }
        } else {
            VStack(alignment: .leading, spacing: 0) {
                header
                Text(widgetText("my_territory"))
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(WidgetPalette.muted)
                    .padding(.top, 9)
                Text("\(entry.territory)")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .minimumScaleFactor(0.55)
                    .lineLimit(1)
                    .foregroundStyle(.white)
                    .shadow(color: .white.opacity(0.22), radius: 8)
                    .padding(.top, 1)
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [WidgetPalette.accent, WidgetPalette.mint],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 40, height: 2)
                    .padding(.top, 6)
                Spacer(minLength: 4)
                HStack(alignment: .bottom, spacing: 0) {
                    bottomStat(widgetText("daily_moved"), entry.dailyMoved, color: .white)
                    Rectangle()
                        .fill(WidgetPalette.divider)
                        .frame(width: 1, height: 24)
                        .padding(.horizontal, 10)
                    bottomStat(widgetText("steps"), entry.steps, color: WidgetPalette.mint)
                }
            }
        }
    }

    private var header: some View {
        HStack(spacing: 6) {
            Image("WidgetIcon")
                .resizable()
                .interpolation(.high)
                .frame(width: 16, height: 16)
            Text(widgetText("app_title"))
                .font(.system(size: 9, weight: .heavy))
                .kerning(0.6)
                .foregroundStyle(WidgetPalette.accent)
                .lineLimit(1)
            Spacer(minLength: 0)
            Circle()
                .fill(WidgetPalette.mint)
                .frame(width: 5, height: 5)
        }
        .frame(height: 16)
    }

    private func bottomStat(_ label: String, _ value: Int, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(label)
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(WidgetPalette.muted)
                .lineLimit(1)
            Text("\(value)")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .monospacedDigit()
                .minimumScaleFactor(0.7)
                .lineLimit(1)
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func compactRow(_ label: String, _ value: Int, accent: Bool) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(.secondary)
            Spacer(minLength: 2)
            Text("\(value)")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .monospacedDigit()
                .lineLimit(1)
                .foregroundStyle(accent ? WidgetPalette.mint : .primary)
        }
    }
}

extension View {
    @ViewBuilder
    func conquestWidgetBackground() -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            containerBackground(for: .widget) {
                WidgetGradientBackground()
            }
        } else {
            background(WidgetGradientBackground())
        }
    }
}

@main
struct ConquestWidget: Widget {
    private let kind = "ConquestWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ConquestProvider()) { entry in
            ConquestWidgetEntryView(entry: entry)
                .conquestWidgetBackground()
        }
        .configurationDisplayName(widgetText("app_title"))
        .description(widgetText("widget_description"))
        .supportedFamilies(supportedFamilies)
    }

    private var supportedFamilies: [WidgetFamily] {
        if #available(iOS 16.0, *) {
            return [.systemSmall, .accessoryCircular, .accessoryRectangular]
        }
        return [.systemSmall]
    }
}
