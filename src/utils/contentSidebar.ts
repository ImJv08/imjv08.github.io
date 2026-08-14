export type ContentSidebarPosition = "left" | "right";

interface GlobalContentSidebarSettings {
  showContentSidebar?: boolean;
  contentSidebarPosition?: ContentSidebarPosition;
}

interface ContentSidebarOverride {
  discriminant: boolean;
  value?: {
    show?: boolean;
    position?: ContentSidebarPosition;
  } | null;
}

export interface ResolvedContentSidebar {
  show: boolean;
  position: ContentSidebarPosition;
}

export function resolveContentSidebar(
  globalSettings: GlobalContentSidebarSettings | undefined,
  pageOverride: ContentSidebarOverride | undefined
): ResolvedContentSidebar {
  if (pageOverride?.discriminant && pageOverride.value) {
    return {
      show: pageOverride.value.show ?? true,
      position: pageOverride.value.position ?? "right",
    };
  }

  return {
    show: globalSettings?.showContentSidebar ?? true,
    position: globalSettings?.contentSidebarPosition ?? "right",
  };
}
