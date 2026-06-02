import { defineCollection } from 'astro:content';
import { glob } from 'astro/loaders';
import { z } from 'astro/zod';

export const CATEGORIES = {
	'zuopinji': '作品集',
	'qita-sheji': '其他设计',
	'sheying': '摄影',
} as const;

export type CategorySlug = keyof typeof CATEGORIES;

export const collections = {
	work: defineCollection({
		loader: glob({ base: './src/content/work', pattern: '**/*.md' }),
		schema: z.object({
			title: z.string(),
			description: z.string(),
			publishDate: z.coerce.date(),
			category: z.enum(['zuopinji', 'qita-sheji', 'sheying']),
			role: z.string().optional(),
			award: z.string().optional(),
			tags: z.array(z.string()),
			img: z.string(),
			img_alt: z.string().optional(),
			meiye_url: z.string().optional(),
			featured: z.boolean().optional().default(false),
			gallery: z.array(z.string()).optional(),
		}),
	}),
};
