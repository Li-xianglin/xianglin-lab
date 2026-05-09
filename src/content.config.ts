import { defineCollection } from 'astro:content';
import { glob } from 'astro/loaders';
import { z } from 'astro/zod';

export const CATEGORIES = {
	'houtai-xitong': '后台系统',
	'app-sheji': 'App 设计',
	'wangye-sheji': '网页设计',
	'keshihua-yemian': '可视化页面',
	'qita': '其他',
} as const;

export type CategorySlug = keyof typeof CATEGORIES;

export const collections = {
	work: defineCollection({
		loader: glob({ base: './src/content/work', pattern: '**/*.md' }),
		schema: z.object({
			title: z.string(),
			description: z.string(),
			publishDate: z.coerce.date(),
			category: z.enum(['houtai-xitong', 'app-sheji', 'wangye-sheji', 'keshihua-yemian', 'qita']),
			role: z.string().optional(),
			award: z.string().optional(),
			tags: z.array(z.string()),
			img: z.string(),
			img_alt: z.string().optional(),
			meiye_url: z.string().optional(),
			featured: z.boolean().optional().default(false),
		}),
	}),
};
