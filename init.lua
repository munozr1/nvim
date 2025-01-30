require('packer').startup(function(use)
	-- Set leader key to <Space>
	vim.api.nvim_set_keymap('', '<Space>', '<Nop>', { noremap = true, silent = true })
	vim.g.mapleader = ' ' -- Set the leader key to Space
	vim.o.wrap = false

	-- use 'ThePrimeagen/harpoon'
	use 'neovim/nvim-lspconfig'
	use 'wbthomason/packer.nvim'
	use 'EdenEast/nightfox.nvim'
	use {
	  'nvim-telescope/telescope.nvim', tag = '0.1.5',
	-- or                            , branch = '0.1.x',
	  requires = { {'nvim-lua/plenary.nvim'} }
	}
	use {
	  'hrsh7th/nvim-cmp',
	  requires = {
	    'hrsh7th/cmp-nvim-lsp',      -- LSP source for nvim-cmp
	    'hrsh7th/cmp-buffer',        -- Buffer source
	    'hrsh7th/cmp-path',          -- Filesystem path source
	    'hrsh7th/cmp-cmdline',       -- Command-line completion
	    'L3MON4D3/LuaSnip',          -- Snippet engine
	    'saadparwaiz1/cmp_luasnip',  -- Snippet completion source
	  }
	}

	vim.cmd('colorscheme nightfox')
	local builtin = require('telescope.builtin')
	vim.keymap.set('n', '<leader>p', builtin.find_files, {})
	vim.keymap.set('n', '<leader>fg', builtin.live_grep, {})
	vim.keymap.set('n', '<leader>fb', builtin.buffers, {})
	vim.keymap.set('n', '<leader>fh', builtin.help_tags, {})
	vim.api.nvim_set_keymap('n', '<Leader>j', '<C-w>h', { noremap = true, silent = true })
	vim.api.nvim_set_keymap('n', '<Leader>k', '<C-w>l', { noremap = true, silent = true })
	vim.api.nvim_set_keymap('n', '<S-h>', ':vertical resize +2<CR>', { noremap = false, silent = true })
	vim.api.nvim_set_keymap('n', '<S-l>', ':vertical resize -2<CR>', { noremap = false, silent = true })

	local cmp = require('cmp')

	cmp.setup({
	  snippet = {
	    expand = function(args)
	      require('luasnip').lsp_expand(args.body) -- Use LuaSnip for snippets
	    end,
	  },
	  window = {
		  completion = cmp.config.window.bordered(),
		  documentation = cmp.config.window.bordered()
	  },
	  mapping = cmp.mapping.preset.insert({
	    ['<C-Space>'] = cmp.mapping.complete(),
	    ['<CR>'] = cmp.mapping.confirm({ select = true }), -- Accept suggestion with Enter
	    ['<Tab>'] = cmp.mapping.select_next_item(),        -- Navigate down
	    ['<S-Tab>'] = cmp.mapping.select_prev_item(),      -- Navigate up
	  }),
	  sources = cmp.config.sources({
	    { name = 'nvim_lsp' , max_item_count = 5},
	    { name = 'luasnip' },  -- Snippet support
	    { name = 'buffer' , max_item_count = 2},   -- Text buffer completion
	    { name = 'path' , max_item_count = 2},     -- File system paths
	  }),
	})

	local capabilities = require('cmp_nvim_lsp').default_capabilities()
	local lspconfig = require('lspconfig')
	lspconfig.clangd.setup({
		capabilities = capabilities,
		on_attach = function(client, bufnr)
		-- Map "gi" to "Go to Implementation"
		vim.api.nvim_buf_set_keymap(bufnr, 
			'n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>',
			{ noremap = true, silent = true })
			end,
		})
		-- Attach LSP to C/C++ files
		vim.api.nvim_create_autocmd('FileType', {
			pattern = { 'c', 'cpp' },
			callback = function()
			vim.lsp.start({
			name = 'clangd',
			cmd = { 'clangd' }, -- Ensure this points to your clangd executable
			root_dir = vim.fs.dirname(vim.fs.find({ 'compile_commands.json', '.git' }, { upward = true })[1]),
		})
		end,
	})

	lspconfig.lua_ls.setup({
		capabilities = capabilities,
	})


end)
